use warnings;
use 5.020;
use experimental qw( signatures );
use stable qw( postderef );
use true;

package App::datasection::Command::extract 0.01 {

    # ABSTRACT: Extract files from Perl source __DATA__ section
    # VERSION

    use App::datasection -command;
    use Data::Section::Pluggable 0.08;
    use Path::Tiny qw( path );

    sub execute ($self, $opt, $args) {

        my @files = map { path($_) } @$args;

        my $dir;
        if($opt->{dir}) {
            $dir = path($opt->{dir})->absolute;
        }

        foreach my $file (@files) {
            my $dir = $dir ? $dir : $file->sibling($file->basename . '.data');

            my $dsp = Data::Section::Pluggable
                ->new( filename => $file );

            if($dsp->get_data_section->%*) {
                $dir->mkdir;
                $dsp->extract($dir);
                say $file;
            }
        }

    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

App::datasection::Command::extract - Extract files from Perl source __DATA__ section

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 datasection extract [ -d DIRECTORY ] SOURCE [ SOURCE ... ]

=head1 DESCRIPTION

This subcommand extracts the files located in the Perl source file
or files into the filesystem.  By default it uses a separate
directory for each source file (named as the source filename with
C<.data> appended to it).  You can alternatively specify your
own directory with the C<-d> option.

=head1 SEE ALSO

=over 4

=item L<App::datasection::Command::extract>

=item L<App::datasection::Command::diff>

=item L<App::datasection::Command::insert>

=back

=cut

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
