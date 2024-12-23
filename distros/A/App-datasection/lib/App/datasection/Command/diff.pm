use warnings;
use 5.020;
use experimental qw( signatures );
use stable qw( postderef );
use true;

package App::datasection::Command::diff 0.01 {

    # ABSTRACT: Show the differences between the filesystem and Perl source __DATA__ section files
    # VERSION

    use App::datasection -command;
    use Data::Section::Writer 0.04;
    use Path::Tiny qw( path );
    use Text::Diff qw( diff );

    sub execute ($self, $opt, $args) {

        my @files = map { path($_) } @$args;

        my $dir;
        if($opt->{dir}) {
            $dir = path($opt->{dir})->absolute;
        }

        foreach my $file (@files) {
            my $dir = $dir ? $dir : $file->sibling($file->basename . '.data');

            my $tmp = Path::Tiny->tempfile;
            $tmp->spew_raw($file->slurp_raw);

            if(-d $dir) {
                my $dsw = Data::Section::Writer
                    ->new(perl_filename => $tmp);

                $dir->visit(sub ($path, $state) {
                    return if $path->is_dir;
                    if(-B $path) {
                        $dsw->add_file($path->relative($dir), $path->slurp_raw, 'base64');
                    } else {
                        $dsw->add_file($path->relative($dir), $path->slurp_utf8);
                    }
                }, { recurse => 1 });

                $dsw->update_file;
                unless($dsw->unchanged) {
                    my $diff = diff \$file->slurp_utf8, \$tmp->slurp_utf8;
                    chomp $diff;
                    my $from = path('a')->child($file);
                    my $to = path('b')->child($file);
                    say "--- $from";
                    say "+++ $to";
                    say $diff;
                }
            }
        }
    }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

App::datasection::Command::diff - Show the differences between the filesystem and Perl source __DATA__ section files

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 datasection insert [ -d DIRECTORY ] SOURCE [ SOURCE ... ]

=head1 DESCRIPTION

This subcommand shows the difference between the files located
on the filesystem into the Perl source file or files.  By
default it uses a separate directory for each source file
(named as the source filename with C<.data> appended to it).
You can alternatively specify your own directory with the
C<-d> option.

B<NOTE>: the format of the diff subject to change.

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
