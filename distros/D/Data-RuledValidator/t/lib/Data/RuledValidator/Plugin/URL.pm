package Data::RuledValidator::Plugin::URL;

our $VERSION = '0.01';

Data::RuledValidator->add_condition_operator
  (
   'url'       => sub{my($self, $v) = @_; return $v =~m{^http://} ? 1 : ()},
  );

1;
__END__

=pod

=head1 NAME

Data::RuledValidator::Plugin::URL

=head1 DESCRIPTION

=head1 Description

=head1 Synopsys

=head1 Author

Ktat, E<lt>ktat@cpan.orgE<gt>

=head1 Copyright

Copyright 2006 by Ktat

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
