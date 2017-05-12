package Bio::Medpost;

our $VERSION = '0.04';

use strict;
use File::Temp qw/ :POSIX /;
use Exporter::Lite;
our @EXPORT = qw(medpost medpost_file);

use Bio::Medpost::Var;
use Cwd qw(abs_path getcwd);


sub _medpost_backend {
    my $file = shift;
    my $argstr = join q/ /, @_;
    $file = abs_path($file);
    my $original_dir = Cwd::abs_path(Cwd::getcwd);
    chdir $Bio::Medpost::Var::medpost_path;
    my $delimiter = $argstr =~ /-penn/ ? '/' : '_';
#    print STDERR "$Bio::Medpost::Var::medpost_script $argstr $file\n";
    my $r = [
	     map{m!(.+)${delimiter}(.+)!; [$1, $2]}
	     split / /, `$Bio::Medpost::Var::medpost_script $argstr $file`
	     ];
    chdir $original_dir;
    return $r;
}

sub medpost_file {
    my $file = shift;
    _medpost_backend($file, @_);
}

sub medpost {
  my $sentence = shift;
  
  my ($fh, $file) = tmpnam();
  
  print {$fh}<<SENTENCE;
.I65536
.Tfoobar
.A$sentence
.E
SENTENCE
  close $fh;

  my $r = _medpost_backend($file, @_);

  unlink $file;

  return $r;
}


1;

__END__

=head1 NAME

Bio::Medpost - Part of speech tagger for MEDLINE text

=head1 USAGE

    use Bio::Medpost;

    $r = medpost('We observed an increase in mitogen-activated protein kinase (MAPK) activity.');

    # You can put options following the text.
    $r = medpost($text_string, qw(-penn));

    # You can input a file
    $r = medpost_file($text_file);

    $r = medpost_file($text_file, qw(-penn -xml));

    use Data::Dumper;

    print Dumper $r;

If you need to change the script path of B<medpost>, please refer to L<Bio::Medpost::Var>.

=head1 SEE ALSO 

http://bioinformatics.oupjournals.org/cgi/content/abstract/20/14/2320

=head1 THE AUTHOR

Yung-chung Lin (a.k.a. xern) E<lt>xern@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=cut
