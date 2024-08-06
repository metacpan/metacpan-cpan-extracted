package Autoconf::Template::UnitTests;

use strict;
use warnings;

use Autoconf::Template::Constants qw(:all);
use Autoconf::Template::Utils     qw(:all);
use Data::Dumper;
use File::Basename qw(basename);
use List::Util     qw(pairs);
use Log::Log4perl  qw(:easy);
use Scalar::Util   qw(reftype);

use parent qw(Exporter);

our @EXPORT = qw(
  create_unit_tests
  create_unit_test_stub
  create_unit_tests_list
);

########################################################################
sub create_unit_tests {
########################################################################
  my ($options) = @_;

  my $root = $options->{root};

  # create unit test scaffolding for .pm, .pl, and .cgi files
  my @unit_tests = (
    ( sprintf '%s/%s', $root, 'src/main/perl/lib' ) =>
      $options->{perl_modules},
    ( sprintf '%s/%s', $root, 'src/main/perl/bin' ) =>
      $options->{perl_scripts},
    ( sprintf '%s/%s', $root, 'src/main/perl/cgi-bin' ) =>
      $options->{cgi_scripts},
  );

  for my $p ( pairs @unit_tests ) {
    my ( $path, $files ) = @{$p};

    TRACE Dumper( [ 'creating unit tests ', $path, $files ] );

    next if !$files;

    if ( reftype($files) eq 'HASH' ) {

      foreach my $dir ( keys %{$files} ) {
        my @tests = @{ $files->{$dir} };

        if ( $dir ne $DOT ) {
          @tests = map {"$dir-$_"} @tests;
        }

        TRACE Dumper( [ 'creating unit tests ', $path, \@tests ] );

        create_unit_test_stub(
          files   => \@tests,
          path    => $path,
          options => $options,
        );
      }
    }
    else {
      TRACE Dumper( [ 'creating unit tests ', $path, $files ] );

      create_unit_test_stub(
        files   => $files,
        path    => $path,
        options => $options,
      );
    }

  }

  return;
}

########################################################################
sub create_unit_test_stub {
########################################################################
  my (%args) = @_;

  my $files = $args{files};

  foreach ( @{$files} ) {
    my $filename = $_;

    my $test_name = flatten_filename($filename);

    render_unit_test(
      %args,
      file => $_,
      type => /[.]pm/xsm ? 'module' : 'script',
      name => $test_name,
    );
  }

  return;
}

########################################################################
sub render_unit_test {
########################################################################
  my (%args) = @_;

  my ( $type, $path, $name, $test_number, $file )
    = @args{qw(type path name test_number file)};

  $test_number ||= 0;

  my $unit_test = sprintf '%s/t/%02d-%s.t.in', $path, $test_number, $name;

  if ( -e $unit_test ) {
    WARN sprintf sprintf 'unit test %s for %s already exists...skipping',
      $unit_test, $args{file};
  }
  else {
    TRACE sprintf 'rendering unit test for %s to %s', $args{file}, $unit_test;

    if ( $type eq 'module' ) {
      $name = $file;
      $name =~ s/\//::/xsmg;
      $name =~ s/[.].*$//xsm;
    }

    render_tt_template(
      { template   => sprintf( '00-%s.t.tt', $type ),
        parameters => { $type => $name },
        outfile    => $unit_test,
      }
    );
  }

  return;
}

# creates unit_test.pl, unit_tests.cgi unit_tests.pm
########################################################################
sub create_unit_tests_list {
########################################################################
  my ($options) = @_;

  my $perl_path = sprintf '%s/src/main/perl', $options->{root};

  my $unit_tests = {};

  for my $p ( pairs qw( cgi-bin cgi bin pl lib pm ) ) {
    my ( $subdir, $type ) = @{$p};

    my $path = sprintf '%s/%s/t', $perl_path, $subdir;

    DEBUG sprintf sprintf 'looking for unit tests in %s', $path;

    my @tests = find_files_of_type(
      path => $path,
      type => 't',
    );

    $unit_tests->{$type} = [ map { 't/' . basename $_ } @tests ];
  }

  $options->{unit_tests} = $unit_tests;

  return $unit_tests;
}

1;

__END__
