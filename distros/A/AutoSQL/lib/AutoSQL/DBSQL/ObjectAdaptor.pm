package AutoSQL::DBSQL::ObjectAdaptor;
use strict;
use AutoSQL::DBSQL::ObjectAdaptor::Abstract; 
use AutoSQL::DBSQL::ObjectAdaptor::General;
use AutoSQL::DBSQL::ObjectAdaptor::Fetch;
use AutoSQL::DBSQL::ObjectAdaptor::Store;
use AutoSQL::DBSQL::ObjectAdaptor::Remove;
use AutoSQL::DBSQL::ObjectAdaptor::OnlyFetch;

our @ISA=qw(AutoSQL::DBSQL::ObjectAdaptor::Abstract
    AutoSQL::DBSQL::ObjectAdaptor::General
    AutoSQL::DBSQL::ObjectAdaptor::Fetch
    AutoSQL::DBSQL::ObjectAdaptor::Store
    AutoSQL::DBSQL::ObjectAdaptor::Remove
    AutoSQL::DBSQL::ObjectAdaptor::OnlyFetch);


1;

__END__

=pod

=head1 NAME

AutoSQL::DBSQL::ObjectAdaptor

=head1 SYNOPSIS


=head1 DESCRIPTION



=head2 Hierarchy

                            Abstract

    General     Fetch       Store       Remove

                OnlyFetch
    

=head1 AUTHOR

Juguang Xiao, juguang at tll.org.sg

=head1 COPYRIGHT

This module is a free software.
You may copy or redistribute it under the same terms as Perl itself.

=cut


