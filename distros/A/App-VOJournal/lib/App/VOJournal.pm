package App::VOJournal;

# vim: set sw=4 ts=4 tw=76 et ai si:

use 5.006;
use strict;
use warnings FATAL => 'all';

use App::VOJournal::VOTL;
use File::Find;
use File::Path qw(make_path);
use Getopt::Long qw(GetOptionsFromArray);

=head1 NAME

App::VOJournal - call Vimoutline on a journal file.

=head1 VERSION

Version v0.4.8

=cut

use version; our $VERSION = qv('v0.4.8');

=head1 SYNOPSIS

Open a file in vimoutliner to write a journal

    use App::VOJournal;

    App::VOJournal->run;

or, on the command line

    perl -MApp::VOJournal -e App::VOJournal->run

=head1 SUBROUTINES/METHODS

=head2 run

This is the only function you need to use this Module. It parses the command
line and determines the date for which you want to write a journal entry.
Then it makes sure all necessary directories are created and starts
vimoutliner with the journal file for that date.

    use App::VOJournal;

    App::VOJournal->run;

B<Note:> App::VOJournal uses L<File::Find>
to search for the last journal file
below the directory given with option C<--basedir>
(default: C<$ENV{HOME}/journal>) and does not follow symbolic links.
Please make sure that this path points to a real directory and no symbolic link.

=cut

sub run {
	my $opt = _initialize(@ARGV);

    if ($opt->{version}) {
        print "App::VOJournal version $VERSION\n";
        return 0;
    }

	my $basedir = $opt->{basedir};
    my $editor  = $opt->{editor};

    my ($day,$month,$year) = _determine_date($opt);

    my $dir = sprintf("%s/%4.4d/%2.2d",
                       $basedir, $year, $month);
    my $path = sprintf("%s/%4.4d/%2.2d/%4.4d%2.2d%2.2d.otl",
                       $basedir, $year, $month, $year, $month, $day);
    my $header = sprintf('; %4.4d-%2.2d-%2.2d',$year,$month,$day);

    my $last_file = _find_last_file($basedir,$path);

    make_path($dir);

    if ($last_file) {
        if ($last_file cmp $path) {
            if ($opt->{resume}) {
                _use_last_file($path,$last_file,$opt,$header);
            }
            else {
                _create_new_file($path,$opt,$header);
            }
        }
    }
    else {
        _create_new_file($path,$opt,$header);
    }
    if ($opt->{resume}) {
        if ($last_file
            && $last_file cmp $path) {
        }
    }
    system($editor, $path);
    return $?;
} # run()

# _create_new_file($path,$opt,$header)
#
# Creates a new vimoutliner file at $path optionally containing a header
# line.
sub _create_new_file {
    my ($path,$opt,$header) = @_;
    my $votl = App::VOJournal::VOTL->new();
    if ($opt->{header}) {
        $votl->insert_line(0,$header);
    }
    $votl->write_file($path);
} # _create_new_file()

# _determine_date($opt)
#
# Determines the date respecting the given options.
#
sub _determine_date {
    my ($opt) = @_;
    my ($day,$month,$year) = (localtime)[3,4,5];
    $year += 1900;
    $month += 1;

    if (my $od = $opt->{date}) {
        if ($od =~ /^\d{1,2}$/) {
            $day = $od;
        }
        elsif ($od =~ /^(\d{1,2})(\d{2})$/) {
            $month = $1;
            $day   = $2;
        }
        elsif ($od =~ /^(\d{4})(\d{2})(\d{2})$/) {
            $year  = $1;
            $month = $2;
            $day   = $3;
        }
    }

    return ($day,$month,$year);
} # _determine_date()

sub _find_files_with_pattern {
    my ($dirname,$pattern) = @_;
    my @files = ();

    if (opendir(my $DIR,$dirname)) {
        while (defined(my $file = readdir($DIR))) {
            push(@files,$file) if ($file =~ /$pattern/);
        }
        closedir($DIR);
    }
    return @files;
} # _find_files_with_pattern

# _find_last_file($basedir, $next_file, $f)
#
# Find the last journal file that can be used as a template for the next
# file.
#
# $basedir - the start directory
# $next_file - the name of the file we want to use next
# $f - optional, a hash with function references to aid testing/debugging
#
sub _find_last_file {
    my ($basedir,$next_file,$f) = @_;
    my $last_file = '';
    my $got_it = 0;
    my $wanted = sub {
        my $this_file = $File::Find::name;

        return if ($got_it);
        #
        # We get the files in reverse order, therefore the first matching
        # file is already the one we are looking for.
        #
        # If we got the file we signal this with $got_it.
        #
        if ($this_file =~ qr|^$basedir/\d{4}/\d{2}/\d{8}[.]otl$|
            && 0 < ($this_file cmp $last_file)
            && 0 >= ($this_file cmp $next_file)) {
            $last_file = $this_file;
            $got_it = 1;
        }
        #
        # The following is only to aid in testing or debugging.
        #
        if ($f->{wanted}) {
            $f->{wanted}->($this_file,$last_file,$next_file,$got_it);
        }
    };
    #
    # Concentrate on the files whose path matches the pattern of journal
    # files and ignore the rest with this preprocess function for
    # File::Find::find().
    #
    # Sort the filenames reverse and ignore all following directory listings
    # if we have already found the last file;
    #
    my $preprocess = sub {
        my @files = ();

        if ($got_it) {
            # leave it empty
        }
        elsif ($File::Find::dir =~ /^$basedir$/) {
            @files = grep { /^\d{4}$/ } @_;
        }
        elsif ($File::Find::dir =~ m|^$basedir/\d{4}$|) {
            @files = grep { /^\d{2}$/ } @_;
        }
        elsif ($File::Find::dir =~ m|^$basedir/\d{4}/\d{2}$|) {
            @files = grep { /^\d{8}\.otl$/ } @_;
        }
        return sort {$b cmp $a} @files;
    };
    find({wanted => $wanted,
          preprocess => $preprocess,
          untaint => 1,                 # needed when running in taint mode
          no_chdir => 1,                # we don't need to chdir
         },$basedir);
    return $last_file;
} # _find_last_file()

sub _use_last_file {
    my ($path,$last_file,$opt,$header) = @_;
    my $votl = App::VOJournal::VOTL->new();
    $votl->read_file_unchecked_boxes($last_file);
    if ($opt->{header}) {
        $votl->insert_line(0,$header);
    }
    $votl->write_file($path);
} # _use_old_file

=head1 COMMANDLINE OPTIONS

=head2 --basedir $dir

Use C<< $dir >> instead of C<< $ENV{HOME}/journal >> as base directory for
the journal files.

=head2 --date [YYYY[MM]]DD

Use a different date than today.

One or two digits change the day in the current month.

Three or four digits change the day and month in the current year.

Eight digits change day, month and year.

The program will not test for a valid date. That means, if you specify
'--date 0230' on the command line, the file for February 30th this year
would be opened.

=head2 --editor $path_to_editor

Use this option to specify an editor other than C<vim> to edit
the journal file.

=head2 --[no]header

Normally every journal file starts with some header lines, indicating the
day the journal is written.

If the option C<--noheader> is given on the command line, this header lines
will be omitted.

=head2 --[no]resume

Look for open checkboxes in the last journal file and carry them forward
to this days journal file before opening it.

This only works if there is no journal file for this day.

The default is C<< --resume >>

=head2 --version

Print the version number and exit.

=cut

# _initialize(@ARGV)
#
# Parse the command line and initialize the program
#
sub _initialize {
	my @argv = @_;
	my $opt = {
        'basedir' => qq($ENV{HOME}/journal),
        'editor'  => 'vim',
        'header'  => 1,
        'resume'  => 1,
	};
    my @optdesc = (
        'basedir=s',
        'date=i',
        'editor=s',
        'header!',
        'resume!',
        'version',
    );
    GetOptionsFromArray(\@argv,$opt,@optdesc);
	return $opt;
} # _initialize()

=head1 AUTHOR

Mathias Weidner, C<< <mamawe at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-vojournal at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-VOJournal>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::VOJournal


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-VOJournal>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-VOJournal>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-VOJournal>

=item * Search CPAN

L<http://search.cpan.org/dist/App-VOJournal/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Mathias Weidner.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of App::VOJournal
