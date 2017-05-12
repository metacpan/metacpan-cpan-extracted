package Moose::Meta::Attribute::Custom::Trait::Digestable;
{
  $Moose::Meta::Attribute::Custom::Trait::Digestable::VERSION = '0.33';
}

sub register_implementation { 'Data::SearchEngine::Meta::Attribute::Trait::Digestable' }

1;
__END__
=pod

=head1 NAME

Moose::Meta::Attribute::Custom::Trait::Digestable

=head1 VERSION

version 0.33

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

