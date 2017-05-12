package CPANPLUS::Shell::Default::Plugins::Changes;

use strict;
use warnings;

use CPANPLUS::Error;
use Locale::Maketext::Simple    Class => 'CPANPLUS', Style => 'gettext';
use DirHandle;

use vars qw[$VERSION];
$VERSION = '0.02';

### Regex to match the names of the changes files
my $changes_re = qr/change(?:s|log)|news/i;

sub plugins { return (changes => 'changes'); }

sub changes {
    my $class = shift;
    my $shell = shift;
    my $cb    = shift;
    my $cmd   = shift;
    my $input = shift || '';
    my $opts  = shift || {};

    ### Get the module name and (optionally) the version.
    my $mod_name;
    ($mod_name = $input) =~ /\S+/;
    if (not $mod_name) {
        error( loc("No module supplied") );
        return;
    }

    ### Fetch module and unpack.
    my $obj = $cb->parse_module(module => $mod_name);
    unless ($obj) {
        error( loc("Couldn't create module object") );
        return;
    }
    $obj->fetch
        or error( loc("Could not fetch '%1'", $obj->package) ),   return;
    my $path = $obj->extract
        or error( loc("Could not extract '%1'", $obj->package) ), return;

    ### Search for a changes file.
    my $changes_file;
    my $dh = DirHandle->new($path);
    if (defined $dh) {
        ($changes_file) = grep { -f && m/$changes_re/ }
                     map { File::Spec->catfile($path, $_) } $dh->read;
    }
    undef $dh;

    unless ($changes_file) {
        error( loc("Could not find a changes file") );
        return;
    }

    ### Read the changes file.
    open my $changes_fh, "<", $changes_file
        or error( loc("Could not open file '$changes_file': $!") ), return;

    my $changes;
    {
        local $/ = undef;
        $changes = <$changes_fh>;
    }
    close $changes_fh;

    ## Display the changes.
    $shell->_pager_open if $changes =~ tr/\n/\n/ > $shell->_term_rowcount;
    print $changes;
    $shell->_pager_close;
}


sub changes_help {
    return loc(
        "    /changes\n" .
        "       Shows the Changes file (or ChangeLog, etc. as appropriate). "
    );
}

1;

=head1 NAME

CPANPLUS::Shell::Default::Plugins::Changes - View a module's Changes file from the CPANPLUS shell

=head1 SYNOPSIS

    ### View Changes file of CPANPLUS
    CPAN Terminal> /changes CPANPLUS

=head1 DESCRIPTION

This plugin allows you to display the Changes (or Changelog, ChangeLog,
etc.) file of a module to get an overview of what (according to the
maintainer) has changed.

=head1 AUTHOR

Module written by Arjen Laarhoven E<lt>arjen@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright (c) 2006  Arjen Laarhoven E<lt>arjen@cpan.orgE<gt>.

This library is free software; you may redistribute and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<cpanp>,
L<CPANPLUS::Shell::Default>,
L<CPANPLUS::Shell::Default::Plugins::HOWTO>

=cut
