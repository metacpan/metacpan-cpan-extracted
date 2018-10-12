package App::CpanfileSlipstop::Writer;
use strict;
use warnings;

use List::Util qw(first);
use PPI::Document;
use PPI::Find;

sub new {
    my ($class, %opts) = @_;

    bless +{
        cpanfile_path => $opts{cpanfile_path},
        dry_run       => $opts{dry_run},
    }, $class;
}

sub cpanfile_path { $_[0]->{cpanfile_path}   }
sub dry_run       { $_[0]->{dry_run} ? 1 : 0 }

my $statement_finder = sub {
    my (undef, $elem) = @_;

    return $elem->isa('PPI::Statement') && $elem->schild(0)->content eq 'requires';
};

sub set_versions {
    my ($self, $version_getter, $logger) = @_;

    my $doc = PPI::Document->new($self->cpanfile_path);
    my $requirements = $doc->find($statement_finder);

    for my $statement (@$requirements) {
        my ($type, $module, @args) = $statement->schildren;

        my $version_range = $version_getter->($module->string);
        next unless $version_range;

        my @words = grep {
            !($_->isa('PPI::Token::Operator') || $_->content eq ';');
        } @args;

        if (@words % 2 == 0) {
            # insert VERSION
            # - requires MODULE;
            # - requries MODULE, KEY => VALUE;
            $self->insert_version($module, $version_range);

            $logger->({
                type   => 'insert',
                module => $module->content,
                before => undef,
                after  => $version_range,
                quote  => quote($module),
            });
        } else {
            # replace VERSION
            # - requries MODULE, VERSION;
            # - requries MODULE, VERSION, KEY => VALUE;
            my $current_version = $words[0];
            $self->replace_version($module, $current_version, $version_range);
            $logger->({
                type   => 'replace',
                module => $module->content,
                before => $current_version->content,
                after  => $version_range,
                quote  => quote($module),
            });
        }
    }

    $self->writedown_cpanfile($doc);
}

sub remove_versions {
    my ($self, $logger) = @_;

    my $doc = PPI::Document->new($self->cpanfile_path);
    my $requirements = $doc->find($statement_finder);

    for my $statement (@$requirements) {
        my ($type, $module, @args) = $statement->schildren;

        my @words = grep {
            !($_->isa('PPI::Token::Operator') || $_->content eq ';');
        } @args;

        if (@words %2 == 1) {
            my ($op, $version) = @args;

            # collect whitespaces between MODULE and VERSION
            my $whitespaces = [];
            my $token = $op->next_sibling;
            while ($token && $token->isa('PPI::Token::Whitespace')) {
                push @$whitespaces, $token;
                $token = $token->next_sibling;
            }

            $op->remove;
            $_->remove for @$whitespaces;
            $version->remove;

            $logger->({
                type   => 'delete',
                module => $module->string,
                before => $version->string,
                after  => undef,
                quote  => quote($module),
            });
        }
    }

    $self->writedown_cpanfile($doc);
}

sub writedown_cpanfile {
    my ($self, $ppi_doc) = @_;

    return if $self->dry_run;

    open my $out, ">", $self->cpanfile_path
        or die sprintf('%s, %s', $self->cpanfile_path, $!);
    print $out $ppi_doc->serialize;
    close $out;
}

sub insert_version {
    my ($self, $module_elem, $version_range) = @_;

    my $quote = quote($module_elem);
    $module_elem->__insert_after(PPI::Token->new(qq{, $quote$version_range$quote}));
}

sub replace_version {
    my ($self, $module_elem, $version_elem, $version_range) = @_;

    my $quote = quote($module_elem);

    # The giving version on cpanfile must be a string or number for preventing to replace expressions.
    return if !($version_elem->isa('PPI::Token::Quote') || $version_elem->isa('PPI::Token::Number'));

    my $prev_token = $version_elem->previous_sibling;
    $version_elem->remove;
    $prev_token->__insert_after(PPI::Token->new(qq{$quote$version_range$quote}));
}

sub quote {
    my ($elem) = @_;

    return $elem->isa('PPI::Token::Quote::Double') ? '"' : "'";
}

1;
