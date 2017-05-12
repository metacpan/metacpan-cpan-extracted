package DB::Introspector::Base::CharColumn;

use strict;

use base q(DB::Introspector::Base::Column);

1; 
__END__

=head1 NAME

DB::Introspector::Base::CharColumn

=head1 EXTENDS

DB::Introspector::Base::Column

=head1 SYNOPSIS

=over 4

use DB::Introspector::Base::CharColumn;

=back
     
=head1 DESCRIPTION

DB::Introspector::Base::CharColumn provides a way to distinguish a Char type,
which represents the class of columns that allow only is a single character
values, from another column type.

=head1 SEE ALSO

=over 4

L<DB::Introspector::Base::Column>


=back


=head1 AUTHOR

Masahji C. Stewart

=head1 COPYRIGHT

The DB::Introspector::Base::CharColumn module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
