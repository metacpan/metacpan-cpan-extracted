package CPANPLUS::Shell::Default::Plugins::Diff;

use strict;
use Text::Diff ();
use Data::Dumper;
use File::Basename;
use Params::Check               qw[check];
use CPANPLUS::Error             qw[error msg];
use Locale::Maketext::Simple    Class => 'CPANPLUS', Style => 'gettext';

use vars qw[$VERSION];
$VERSION = '0.01';

local $Data::Dumper::Indent = 1;

=head1 NAME

CPANPLUS::Shell::Default::Plugins::Diff

=head1 SYNOPSIS

    ### diff version 1.3 and 1.4
    CPAN Terminal> /diff DBI 1.3 1.4

    ### diff version 1.3 against the most recent on CPAN
    CPAN Terminal> /diff DBI 1.3 

    ### diff your installed version against the most 
    ### recent on CPAN
    CPAN Terminal> /diff DBI 

    ### use context style diff
    ### other options are: Unified, OldStyle
    CPAN Terminal> /diff DBI --style=Context

    ### list help from withing the shell:
    CPAN Terminal> /? diff 

=head1 DESCRIPTION

This plugin allows you to diff 2 versions of modules and see what
code changes have taken place.

=cut

sub plugins { return ( diff => 'diff' ) }

sub diff {
    my $class   = shift;
    my $shell   = shift;
    my $cb      = shift;
    my $cmd     = shift;
    my $input   = shift || '';
    my $opts    = shift || {};
    my $verbose = $cb->configure_object->get_conf('verbose');

    my($name, $from, $to) = split /\s+/, $input;

    my $style;
    {   my $tmpl = {
            style   => { default => "Unified", store => \$style,
                            allow => [qw|Unified Context OldStyle|] },
        };                            
    
        check( $tmpl, $opts, 1 ) or return;
    }
    
    error(loc("No module supplied")), return unless $name;
    
    my $mod = $cb->parse_module( module => $name ) or (
        error(loc("Could not parse module name '%1'"), $name),
        return
    );
    
    ### no 'from'?
    unless( defined $from && length $from ) {
        
        ### not installed?
        unless( $mod->installed_file ) {
            error(loc("'%1' is not installed, need %2 version", $name, 'FROM'));
            return;
        }
        
        $from = $mod->installed_version;
    }
    
    ### no 'to'?
    $to = $mod->version unless defined $to && length $to;
    
    msg(loc("Diffing '%1' version '%2' against version '%3'", 
        $name, $from, $to), $verbose);
    
    if( "$to" eq "$from" ) {
        error(loc("TO ('%1') and FROM ('%2') are identical", $to, $from));
        return;
    }        
    
    ### fetch them, extract, and store    
    my $href = {};
    {   my %map  = ( FROM => $from, TO => $to );
        
        while ( my($txt,$ver) = each %map ) {
            my $obj = $cb->parse_module( 
                                module => $mod->package_name . '-' . $ver );
            error(loc("Couldn't create '%1' object'",'FROM')), return
                unless $obj;
    
            $obj->fetch     
                or error(loc("Could not fetch '%1'",$txt)),     return;
            $obj->extract   
                or error(loc("Could not extract '%1'",$txt)),   return;
    
            
            $href->{$txt} = $obj;
        }
    }
    
    
    ### make 2 hashes of the files in each tree...
    ### be sure to strip the leading extract dir, as that will
    ### cause mismatches further down. IE:
    ### foo-bar-0.1/README vs foo-bar-0.2/README
    ### the 'foo-bar' part is also present in the 'extract' status
    ### so one of the 2 has to be removed either way.
    ### use index 1 rather than 0, as 0 will usually hold just a dirname
    ### which will mess up dirname() and return undef...
    
    my $fstatus = $href->{FROM}->status;
    my $fbase   = dirname( $fstatus->files->[1] );

    my $tstatus = $href->{ TO }->status;
    my $tbase   = dirname( $tstatus->files->[1] );
    
    my %old = map { s/^$fbase//; $_ => $_ } @{ $fstatus->files };
    my %new = map { s/^$tbase//; $_ => $_ } @{ $tstatus->files };    
    
    my $diff;
    
    for my $file ( sort keys %old ) {
    
        my $exists      = delete $new{$file};
        my $from_file   = File::Spec->catfile( $fstatus->extract, $file );
        my $to_file     = File::Spec->catfile( $tstatus->extract, $file );

        next if -d $from_file;
    
        ### if the file doesn't exist in the target 'to' dir,
        ### pass a reference to 'undef'
        $diff .= Text::Diff::diff(
            $from_file,
            $exists ? $to_file : \undef,
            {   FILENAME_A  => $from_file,
                FILENAME_B  => $exists ? $to_file : '/dev/null',
                STYLE       => $style,
            }
        );          
    }
    
    ### any files left in 'new' are new files, treat 'm as such
    for my $file ( sort keys %new ) {
        my $to_file = File::Spec->catfile( $tstatus->extract, $file );

        next if -d $to_file;
        
        $diff .= Text::Diff::diff(
            \undef,
            $to_file,
            {   FILENAME_A  => '/dev/null',
                FILENAME_B  => $file,
                STYLE       => $style,
            }
        );
    }
    
    $shell->_pager_open if $diff =~ tr/\n/\n/ > $shell->_term_rowcount;
    print $diff;
    $shell->_pager_close;
    
}

sub diff_help { 
    return loc(
        "    /diff Module [[FROM] TO]  [--style=STYLE]\n" .
        "       Diffs the contents of 2 releases\n".
        "       if TO is not supplied, the most recent release is used\n".
        "       if FROM is not supplied, the currently installed version,\n" .
        "       if any, is used\n".
        "       Valid values for STYLE are: 'Unified', 'Context', 'OldStyle'\n"
    );
}

1;


=pod

=head1 AUTHOR

This module by
Jos Boumans E<lt>kane@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright (c) 2005, Jos Boumans E<lt>kane@cpan.orgE<gt>.
All rights reserved.

This library is free software;
you may redistribute and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<CPANPLUS::Shell::Default>, L<cpanp>,
L<CPANPLUS::Shell::Default::Plugins::HOWTO>

=cut

# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
