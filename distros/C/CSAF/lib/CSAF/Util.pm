package CSAF::Util;

use 5.010001;
use strict;
use warnings;
use utf8;

use Cpanel::JSON::XS;
use Data::Dumper;
use File::Basename        qw(dirname);
use File::Spec::Functions qw(catfile);
use GnuPG::Handles;
use GnuPG::Interface;
use IO::Handle;
use List::Util qw(first);
use Time::Piece;

use Exporter 'import';

our @EXPORT_OK = (qw[
    schema_cache_path resources_path tt_templates_path
    parse_datetime tracking_id_to_well_filename
    collect_product_ids file_read file_write product_in_group_exists
    list_cves gpg_sign gpg_verify log_formatter uniq
]);

my %LOG_LEVELS = (
    0 => 'EMERGENCY',
    1 => 'ALERT',
    2 => 'CRITICAL',
    3 => 'ERROR',
    4 => 'WARNING',
    5 => 'NOTICE',
    6 => 'INFO',
    7 => 'DEBUG',
    8 => 'TRACE',
);

{
    no warnings qw{ redefine };
    sub Time::Piece::TO_JSON { shift->datetime }
}

sub schema_cache_path { catfile(resources_path(),  'cache') }
sub tt_templates_path { catfile(resources_path(),  'template') }
sub resources_path    { catfile(dirname(__FILE__), 'resources') }

sub list_cves {

    my $csaf = shift;
    my @cves = ();

    $csaf->vulnerabilities->each(sub {
        push @cves, $_->cve;
    });

    return wantarray ? @cves : "@cves";

}

# List::Util::uniq is included in the core module since Perl v5.26.0
sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

sub parse_datetime {

    my $datetime = shift;
    return unless $datetime;

    return $datetime if ($datetime->isa('Time::Piece'));

    return Time::Piece->new($datetime) if ($datetime =~ /^([0-9]+)$/);
    return Time::Piece->new            if ($datetime eq 'now');

    return Time::Piece->strptime($1, '%Y-%m-%dT%H:%M:%S') if ($datetime =~ /(\d{4}-\d{2}-\d{2}[T]\d{2}:\d{2}:\d{2})/);
    return Time::Piece->strptime($1, '%Y-%m-%d %H:%M:%S') if ($datetime =~ /(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2})/);
    return Time::Piece->strptime($1, '%Y-%m-%d')          if ($datetime =~ /(\d{4}-\d{2}-\d{2})/);

}

sub tracking_id_to_well_filename {

    my $id = shift;

    $id = lc $id;
    $id =~ s/[^+\-a-z0-9]+/_/g;    # Rif. 5.1 (Additional Conventions - Filename)

    return "$id.json";

}

sub collect_product_ids {

    my $item        = shift;
    my @product_ids = ();

    my $ref_item = ref($item);

    if ($ref_item =~ /Branch$/) {

        if ($item->has_product) {
            push @product_ids, $item->product->product_id;
        }

        foreach (@{$item->branches->items}) {
            push @product_ids, collect_product_ids($_);
        }

    }

    if ($ref_item =~ /FullProductName$/) {
        push @product_ids, $item->product_id;
    }

    return @product_ids;

}

sub product_in_group_exists {

    my ($csaf, $product_id, $group_id) = @_;

    my $exists = 0;

    $csaf->product_tree->product_groups->each(sub {

        my ($group) = @_;

        if ($group->group_id eq $group_id) {
            if (first { $product_id eq $_ } @{$group->product_ids}) {
                $exists = 1;
                return;
            }
        }

    });

    return $exists;

}

sub file_read {

    my $file = shift;

    if (ref($file) eq 'GLOB') {
        return do { local $/; <$file> };
    }

    return do {
        open(my $fh, '<', $file) or Carp::croak qq{Failed to read file: $!};
        local $/ = undef;
        <$fh>;
    };

}

sub file_write {

    my ($file, $content) = @_;

    my $fh = undef;

    if (ref($file) eq 'GLOB') {
        $fh = $file;
    }
    else {
        open($fh, '>', $file) or Carp::croak "Can't open file: $!";
    }

    $fh->autoflush(1);

    print $fh $content;
    close($fh);

}

sub gpg_get_result_from_handles {

    my %handle = @_;

    my %result = ();
    my $error  = undef;

    foreach (qw[stdout stderr logger status]) {

        $result{$_} = do { local $/ = undef; readline $handle{$_} };
        delete $result{$_} unless $result{$_} && $result{$_} =~ /\S/s;

        if (not close $handle{$_}) {
            $error ||= "Can't close gnupg $_ handle: $!";
        }

    }

    Carp::carp $error if $error;

    $result{exit_code} = ($? >> 8);

    return \%result;

}

sub gpg_verify {

    my %args = (signed => undef, file => undef, @_);

    my %handle = (
        stdin  => IO::Handle->new,
        stdout => IO::Handle->new,
        stderr => IO::Handle->new,
        logger => IO::Handle->new,
        status => IO::Handle->new
    );

    local $ENV{LANG} = 'C';

    my $gnupg = GnuPG::Interface->new();

    $gnupg->options->hash_init(meta_interactive => 0);

    my $pid = $gnupg->wrap_call(
        commands     => ['--verify'],
        command_args => [$args{signed}, $args{file}],
        handles      => GnuPG::Handles->new(%handle)
    );
    waitpid $pid, 0;

    return gpg_get_result_from_handles(%handle);

}

sub gpg_sign {

    my %args = (passphrase => undef, plaintext => undef, key => undef, recipients => [], @_);

    my %handle = (
        stdin  => IO::Handle->new,
        stdout => IO::Handle->new,
        stderr => IO::Handle->new,
        logger => IO::Handle->new,
        status => IO::Handle->new
    );

    local $ENV{LANG} = 'C';

    my $gnupg = GnuPG::Interface->new();

    $gnupg->options->hash_init(armor => 1, meta_interactive => 0);
    $gnupg->options->default_key($args{key}) if defined $args{key};
    $gnupg->options->push_recipients($_) for (@{$args{recipients}});

    $gnupg->passphrase($args{passphrase});

    my $pid = $gnupg->detach_sign(handles => GnuPG::Handles->new(%handle));

    print {$handle{stdin}} ($args{plaintext});
    close $handle{stdin};

    waitpid $pid, 0;

    return gpg_get_result_from_handles(%handle);

}

sub log_formatter {

    my ($category, $level, $format, @params) = @_;

    @params = map { ref $_ ? Dumper($_) : $_ } @params;

    my $message = sprintf($format, @params);
    my $now     = Time::Piece->new->datetime;

    return sprintf('[%s] [%s] [%s] [%s] %s', $now, $$, lc($LOG_LEVELS{$level}), $category, $message);

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Util - Generic utility for CSAF

=head1 SYNOPSIS

    use CSAF::Util qw(tracking_id_to_well_filename);

    say tracking_id_to_well_filename($csaf->document->tracking->id);

=head1 DESCRIPTION

Generic utility for L<CSAF>.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-CSAF/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-CSAF>

    git clone https://github.com/giterlizzi/perl-CSAF.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023-2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
