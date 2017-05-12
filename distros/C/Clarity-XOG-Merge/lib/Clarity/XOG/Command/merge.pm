package Clarity::XOG::Command::merge;

use strict;
use warnings;

use Clarity::XOG -command;
use Clarity::XOG::Merge;

use Data::Dumper;
use File::Find::Rule;

sub opt_spec
{
        (
         [ "out|o=s",    "Write result to that file",                 { default => "XOGMERGE.xml" } ],
         [ "in|i=s",     "Search default input files in that subdir", { default => "." } ],
         [ "verbose|v",  "Be verbose",                                { default => 0 } ],
         [ "debug|d",    "Output debugging info",                     { default => 0 } ],
         [ "force|f",    "Force overwrite of existing output file.",  { default => 0 } ],
        );
}

sub abstract { "merge several files" }

sub description {

        "  Merge Clarity project files.

  You either specify the files to merge or it finds all *.xml files
  either in local directory or the directory you specified with -i.

  Specify an output file with -o, default is 'XOGMERGE.xml' in current
  directory. If you want to force overwrite an existing output file
  without asking then specify -f.

  During the process a temporary directory is created, used, and
  cleaned up at the end.

  To self-test the xogtool use the 'xogtool selftest'.

Options:"; }

# The merge works as follows: In a first pass there is some XML element
# counting through the source xml files; that's kind of an
# optimization. In a 2nd pass all source xml files are read again, now
# all contained projects are sorted into temporary files respectively
# and then appended to final xml output file.


sub validate_args {
        my ($self, $opt, $args) = @_;

        # no-op
}

sub find_local_project_files {
        my ($self, $opt, $args, $out_file) = @_;

        my $in_dir   = $opt->{in};

        my @files =
            grep { $_ ne $out_file }
            File::Find::Rule
                        ->maxdepth(1)
                        ->file
                        ->name('*.XML', '*.xml')
                        ->in($in_dir);
        if ($opt->{verbose}) {
                print "Merge files:\n";
                print "  $_\n" foreach @files;
        }
        return \@files;
}

sub execute {
        my ($self, $opt, $args) = @_;

        print STDERR "opt:  ", Dumper($opt)  if $opt->{debug};
        print STDERR "args: ", Dumper($args) if $opt->{debug};

        my $out_file = $opt->{out} || 't/xog-out.xml';
        my $files    = scalar @$args ? $args : $self->find_local_project_files($opt, $args, $out_file);

        my $merger = Clarity::XOG::Merge->new
            (
             files    => $files,
             out_file => $out_file,
             verbose  => $opt->{verbose},
             debug    => $opt->{debug},
             force    => $opt->{force},
            );
        $merger->Main;
}

1;

__END__

=pod

=head1 NAME

Clarity::XOG::Command::merge - xogtool subcommand 'merge'

=head1 ABOUT

This is the class for C<xogtool merge>. It merges several XOG files.

See also L<xogtool|xogtool> for details.

=head1 AUTHOR

Steffen Schwigon, C<< <ss5 at renormalist.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-clarity-xog-merge
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Clarity-XOG-Merge>. I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2010-2011 Steffen Schwigon, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
