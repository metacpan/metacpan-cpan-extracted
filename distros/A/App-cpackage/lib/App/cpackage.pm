package App::cpackage;

use 5.010;
use strict;
use warnings;
use App::cpanminus 1.5002;  # Dependency check
use Capture::Tiny qw/capture/;
use Config;
use File::Copy;
use File::Spec::Functions qw/catfile curdir/;

our $VERSION = '1.01';

sub run {
    die "Usage: $0 cpanm_options module_name\n" unless @ARGV;
    
    my $module_name   = pop @ARGV;
    my @cpanm_options = @ARGV;
    
    #--Make our own copy of the 'cpanm' executable------------------------------
    
    my $cpanm = catfile($Config{bin},'cpanm');
    die "Cannot find cpanm (looking in $Config{bin})" unless -e -r $cpanm;
    die "Cannot write to current directory" unless -w curdir;
    
    mkdir 'bin';
    copy $cpanm => catfile(curdir, 'bin', 'cpanm');
    
    
    #--Use cpanm to get dependency list-----------------------------------------
    
    mkdir 'extlib';
    mkdir 'packages';
    
    say "Analysing dependencies for $module_name";
    my ($dist_list, $log) = capture {
        system($^X, 'bin/cpanm', @cpanm_options, '--format', 'dists', '--save-dists', 'packages', '-L', 'extlib', '--scandeps', $module_name);
    };
    
    die "Couldn't extract depedencies:\n\n$log\n" unless $dist_list;
    rmdir 'extlib';
    
    
    #--Write installer script---------------------------------------------------
    
    my $installer = 'install.pl';
    open my $fh, '>', $installer;
    
    print $fh <<'EOT';
#! /usr/bin/env perl

use strict;
use warnings;

my @cpanm_options = @ARGV;

while (<DATA>) {
    chomp;
    if (my ($author) = split '/') {
        my $a  = substr($author,0,1);
        my $ab = substr($author,0,2);
        
        system($^X, 'bin/cpanm', @cpanm_options, "packages/authors/id/$a/$ab/$_");
    }
}
__DATA__
EOT
    
    print $fh $dist_list;
    close $fh;
    
    say "Installer script written to $installer";
}

=head1 NAME

App::cpackage - Create installation packages from CPAN modules

=head1 DESCRIPTION

Back-end module for the L<cpackage> command.

See C<perldoc cpackage> for usage information.

=head1 AUTHOR

Jon Allen (JJ) <jj@jonallen.info>

=head1 LICENSE

Copyright 2011 Jon Allen (JJ).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of App::cpackage
