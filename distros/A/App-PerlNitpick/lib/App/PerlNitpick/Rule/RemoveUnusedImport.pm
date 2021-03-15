package App::PerlNitpick::Rule::RemoveUnusedImport;
# ABSTRACT: Remove unused import

=encoding UTF-8

=head1 DESCRIPTION

This nitpicking rule removes imports that are explicitly put there, but
not used in the same file.

For example, C<Dumper> is not used this simple program:

    use Data::Dumper 'Dumper';
    print 42;

And it will be removed by this program.

=cut

use Moose;
use PPI::Document;
use PPIx::Utils qw(is_function_call);

has idx => (
    is => 'rw',
    required => 0,
);

sub rewrite {
    my ($self, $doc) = @_;

    $self->_build_idx($doc);
    my @violations = $self->find_violations($doc);
    for my $tuple (@violations) {
        my ($word, $import) = @$tuple;
        my @args_literal = $import->{expr_qw}->literal;
        my @new_args_literal = grep { $_ ne $word } @args_literal;

        if (@new_args_literal == 0) {
            $import->{expr_qw}{content} = 'qw()';
            $import->{expr_qw}{sections}[0]{size} = length($import->{expr_qw}{content});
        } else {
            # These 3 lines should probably be moved to the internal of PPI::Token::QuoteLike::Word
            $import->{expr_qw}{content} =~ s/\s ${word} \s/ /gsx;
            $import->{expr_qw}{content} =~ s/\b ${word} \s//gsx;
            $import->{expr_qw}{content} =~ s/\s ${word} \b//gsx;
            $import->{expr_qw}{content} =~ s/\b ${word} \b//gsx;
            $import->{expr_qw}{sections}[0]{size} = length($import->{expr_qw}{content});

            my @new_args_literal = $import->{expr_qw}->literal;
            if (@new_args_literal == 0) {
                $import->{expr_qw}{content} = 'qw()';
                $import->{expr_qw}{sections}[0]{size} = length($import->{expr_qw}{content});
            }
        }
    }

    return $doc;
}

sub _build_idx {
    my ($self, $doc) = @_;
    my $idx = {
        used_count => {},
    };

    for my $el (@{ $doc->find( sub { $_[1]->isa('PPI::Token::Word') }) ||[]}) {
        unless ($el->parent->isa('PPI::Statement::Include') && (!$el->sprevious_sibling || $el->sprevious_sibling eq "use")) {
            $idx->{used_count}{"$el"}++;
            if ($el =~ /::/ && is_function_call($el)) {
                my ($module_name, $func_name) = $el =~ m/\A(.+)::([^:]+)\z/;
                $idx->{used_count}{$module_name}++;
                $idx->{used_count}{$func_name}++;
            }
        }
    }
    $self->idx($idx);
    return $idx;
}

sub looks_like_unused {
    my ($self, $module_name) = @_;
    return ! $self->idx->{used_count}{$module_name};
}

sub find_violations {
    my ($self, $elem) = @_;

    my %imported;
    my %is_special = map { $_ => 1 } qw(MouseX::Foreign);

    my $include_statements = $elem->find(sub { $_[1]->isa('PPI::Statement::Include') }) || [];
    for my $st (@$include_statements) {
        next unless $st->type eq 'use';
        my $included_module = $st->module;
        next if $included_module =~ /\A[a-z0-9:]+\Z/ || $is_special{"$included_module"};

        my $expr_qw = $st->find( sub { $_[1]->isa('PPI::Token::QuoteLike::Words'); }) or next;

        if (@$expr_qw == 1) {
            my $expr = $expr_qw->[0];

            my $expr_str = "$expr";

            # Remove the quoting characters.
            substr($expr_str, 0, 3) = '';
            substr($expr_str, -1, 1) = '';

            my @words = split ' ', $expr_str;
            for my $w (@words) {
                next if $w =~ /\A [:\-\+\$@%]/x;
                push @{ $imported{$w} //=[] }, {
                    statement => $st,
                    expr_qw   => $expr,
                };
            }
        }
    }

    my %used;
    for my $el_word (@{ $elem->find( sub { $_[1]->isa('PPI::Token::Word') }) ||[]}) {
        $used{"$el_word"}++;
    }

    my @violations;
    my @to_report = grep { !$used{$_} } (sort keys %imported);

    for my $tok (@to_report) {
        for my $import (@{ $imported{$tok} }) {
            push @violations, [ $tok, $import ];
        }
    }

    return @violations;
}

1;
