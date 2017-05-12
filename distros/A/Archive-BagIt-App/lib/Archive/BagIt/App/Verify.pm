package Archive::BagIt::App::Verify;

use strict;
use warnings;

our $VERSION = '0.049'; # VERSION

use MooseX::App::Command;

parameter 'bag_path' => (
  is=>'rw',
  isa=>'Str',
  documentation => q[This is the path to run verify on],
  required => 1,
);

option 'return_all_errors' => (
  is => 'rw',
  isa => 'Bool',
  documentation => q[collect all errors rather than dying on first],
);

option 'fast' => (
  is => 'rw',
  isa => 'Bool',
  documentation => q[use Archive::BagIt::Fast instead...],
);


sub abstract {
  return 'verifies a valid bag';
}


sub run {
  my ( $self) = @_;

  use Archive::BagIt;
  my $bag_path = $self->bag_path;
  my ($bag);
  if($self->fast) {
    use Archive::BagIt::Fast;
    $bag = Archive::BagIt::Fast->new($bag_path);
  }
  else {
    $bag = Archive::BagIt->new($bag_path);
  }
  eval {
      $bag->verify_bag();
  };
  if ($@) {
      print "FAIL: ".$bag_path." : $! $@\n";
  }
  else {
      print "PASS: ".$bag_path."\n";
  }
}

1

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::App::Verify

=head1 VERSION

version 0.049

=for Pod::Coverage abstract run

=head1 NAME

Archive::BagIt::App::Verify - verifies a bag

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Archive::BagIt::App/>.

=head1 SOURCE

The development version is on github at L<http://github.com/rjeschmi/Archive-BagIt-App>
and may be cloned from L<git://github.com/rjeschmi/Archive-BagIt-App.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/rjeschmi/Archive-BagIt-App/issues>.

=head1 AUTHOR

Rob Schmidt <rjeschmi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Rob Schmidt and William Wueppelmann.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
