package Data::Printer::Filter::StructDumb 0.001;
use v5.36.0;

# ABSTRACT: a Data::Printer filter for Struct::Dumb

use Data::Printer::Filter;

#pod =head1 SYNOPSIS
#pod
#pod By default, Struct::Dumb on v5.40 and later would print as, at best, C<opaque
#pod object>.  On earlier perls, it would cause an exception.  Neither of these is
#pod ideal.  This filter will dump the I<actual properties> of the struct.
#pod
#pod Right now, it's something like this:
#pod
#pod   data [
#pod     [0] struct main::Point {
#pod           x => 1,
#pod           y => 2,
#pod         },
#pod     [1] struct main::Point3D {
#pod           x => 10,
#pod           y => -20,
#pod           z => "ten",
#pod         },
#pod   ]
#pod
#pod In the future, there may be more options for compact formatting, omitting field
#pod names, and who knows what else.
#pod
#pod =cut

filter 'Struct::Dumb::Struct' => sub {
  my ($object, $ddp) = @_;

  require Struct::Dumb;
  my $dump = Struct::Dumb::dumper_info($object);

  my $to_dump = {
    map {; $dump->{fields}[$_] => $dump->{values}[$_] } keys $dump->{fields}->@*
  };

  my $str = "struct " . (ref $object) . " "
          .  $ddp->parse($to_dump);

  return $str;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Printer::Filter::StructDumb - a Data::Printer filter for Struct::Dumb

=head1 VERSION

version 0.001

=head1 SYNOPSIS

By default, Struct::Dumb on v5.40 and later would print as, at best, C<opaque
object>.  On earlier perls, it would cause an exception.  Neither of these is
ideal.  This filter will dump the I<actual properties> of the struct.

Right now, it's something like this:

  data [
    [0] struct main::Point {
          x => 1,
          y => 2,
        },
    [1] struct main::Point3D {
          x => 10,
          y => -20,
          z => "ten",
        },
  ]

In the future, there may be more options for compact formatting, omitting field
names, and who knows what else.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
