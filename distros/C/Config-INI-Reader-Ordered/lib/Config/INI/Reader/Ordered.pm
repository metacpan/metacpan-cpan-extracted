use strict;

package Config::INI::Reader::Ordered;
$Config::INI::Reader::Ordered::VERSION = '0.020';
# ABSTRACT: .ini-file parser that returns sections in order

use Config::INI::Reader;
use vars qw(@ISA $VERSION);
BEGIN { @ISA = qw(Config::INI::Reader) }

#pod =head1 SYNOPSIS
#pod
#pod If F<family.ini> contains:
#pod
#pod   admin = rjbs
#pod
#pod   [rjbs]
#pod   awesome = yes
#pod   height = 5' 10"
#pod
#pod   [mj]
#pod   awesome = totally
#pod   height = 23"
#pod
#pod Then when your program contains:
#pod
#pod   my $array = Config::INI::Reader->read_file('family.ini');
#pod
#pod C<$array> will contain:
#pod
#pod   [
#pod     [ '_'  => { admin => 'rjbs' } ],
#pod     [
#pod       rjbs => {
#pod         awesome => 'yes',
#pod         height  => q{5' 10"},
#pod       }
#pod     ],
#pod     [ 
#pod       mj   => {
#pod         awesome => 'totally',
#pod         height  => '23"',
#pod       }
#pod     ],
#pod   ]
#pod
#pod =head1 DESCRIPTION
#pod
#pod Config::INI::Reader::Ordered is a subclass of L<Config::INI::Reader> which
#pod preserves section order.  See L<Config::INI::Reader> for all documentation; the
#pod only difference is as presented in the L</SYNOPSIS>.
#pod
#pod =cut

sub change_section {
  my ($self, $section) = @_;
  $self->SUPER::change_section($section);
  $self->{order} ||= [];
  push @{ $self->{order} }, $section
    unless grep { $_ eq $section } @{ $self->{order} };
}

sub set_value {
  my ($self, $name, $value) = @_;
  $self->SUPER::set_value($name, $value);
  unless ($self->{order}) {
    $self->{order} = [ $self->starting_section ];
  }
}

sub finalize {
  my ($self) = @_;
  my $data = [];
  for my $section (@{ $self->{order} || [] }) {
    push @$data, [ $section, $self->{data}{$section} ];
  }
  $self->{data} = $data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::INI::Reader::Ordered - .ini-file parser that returns sections in order

=head1 VERSION

version 0.020

=head1 SYNOPSIS

If F<family.ini> contains:

  admin = rjbs

  [rjbs]
  awesome = yes
  height = 5' 10"

  [mj]
  awesome = totally
  height = 23"

Then when your program contains:

  my $array = Config::INI::Reader->read_file('family.ini');

C<$array> will contain:

  [
    [ '_'  => { admin => 'rjbs' } ],
    [
      rjbs => {
        awesome => 'yes',
        height  => q{5' 10"},
      }
    ],
    [ 
      mj   => {
        awesome => 'totally',
        height  => '23"',
      }
    ],
  ]

=head1 DESCRIPTION

Config::INI::Reader::Ordered is a subclass of L<Config::INI::Reader> which
preserves section order.  See L<Config::INI::Reader> for all documentation; the
only difference is as presented in the L</SYNOPSIS>.

=head1 AUTHOR

Hans Dieter Pearcey <hdp@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Hans Dieter Pearcey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
