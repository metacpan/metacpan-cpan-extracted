package DB::Introspector::Base::BooleanColumn;

use strict;

use base qw( DB::Introspector::Base::Column );

1;
__END__

=head1 NAME

DB::Introspector::Base::BooleanColumn

=head1 EXTENDS

DB::Introspector::Base::Column

=head1 SYNOPSIS

=over 4

use DB::Introspector::Base::BooleanColumn;

=back
     
=head1 DESCRIPTION

DB::Introspector::Base::BooleanColumn provides a way to distinguish a Boolean
type from another column type.

=head1 SEE ALSO

=over 4

L<DB::Introspector::Base::Column>


=back


=head1 AUTHOR

Masahji C. Stewart

=head1 COPYRIGHT

The DB::Introspector::Base::BooleanColumn module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
