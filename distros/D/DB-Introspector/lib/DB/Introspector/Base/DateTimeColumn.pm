package DB::Introspector::Base::DateTimeColumn;

use strict;

use base qw( DB::Introspector::Base::Column );


1;
__END__

=head1 NAME

DB::Introspector::Base::DateTimeColumn

=head1 EXTENDS

DB::Introspector::Base::Column

=head1 SYNOPSIS

=over 4

use DB::Introspector::Base::DateTimeColumn;

=back
     
=head1 DESCRIPTION

DB::Introspector::Base::DateTimeColumn provides a way to distinguish a DateTime
type from another column type.

=head1 SEE ALSO

=over 4

L<DB::Introspector::Base::Column>


=back


=head1 AUTHOR

Masahji C. Stewart

=head1 COPYRIGHT

The DB::Introspector::Base::DateTimeColumn module is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
