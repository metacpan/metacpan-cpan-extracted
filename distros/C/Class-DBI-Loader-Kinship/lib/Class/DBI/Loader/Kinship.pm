package Class::DBI::Loader::Kinship;

use 5.008008;
use base 'Class::DBI::Loader';
our $VERSION = '0.03';

use Class::DBI::Loader::k_Pg ;
## Class::DBI::Loader::k_Pg is masquerading as Class::DBI::Loader::Pg
$INC{'Class/DBI/Loader/Pg.pm'} = '::k_Pg masquerades in its place';

# load Class::DBI::Loader::Generic here to prevent 
# someone loading later (and redefine our subs) .
use Class::DBI::Loader::Generic;

package Class::DBI::Loader::Generic;
use strict;
use warnings;
no warnings 'redefine';

my %kinships ;

sub _has_a_many {
       my ( $self, $fk_tn, $fk_cn, $uk_tn, $uk_cn ) = @_;
       my $fk_class = $self->find_class($fk_tn) or return;
       my $uk_class = $self->find_class($uk_tn) or return;
       my $mn= lc $fk_class . 's';

       warn qq/\# Has_a relationship\n/                       if $self->debug;
       my $hasa = "$fk_class ->has_a ( $fk_cn, $uk_class )"; 
       warn "$hasa \n\n"                                      if $self->debug;
       push @{$kinships{ $fk_class }{has_a}} , $hasa ;
       $fk_class -> has_a( $fk_cn, $uk_class );

       warn qq/\# Has_many relationship\n/                    if $self->debug;
       my $many  = "$uk_class ->has_many ( $mn,$fk_class,$fk_cn )";
       warn "$many \n\n"                                      if $self->debug;
       push @{$kinships{ $uk_class }{has_many}} , $many ;
       $uk_class -> has_many( $mn, $fk_class, $fk_cn ) ;
}

sub _relationships {
    my $self = shift;
    my $ns  = $self->{_namespace}||'public' ;
    foreach my $table ( $self->tables ) {
        my $dbh = $self->find_class($table)->db_Main;
        if ( my $sth = $dbh->foreign_key_info( '', $ns, '', '',$ns, $table) ) {
            for my $res ( @{ $sth->fetchall_arrayref( {} ) } ) {
                my $fk_tn = $res->{ FK_TABLE_NAME };
                my $fk_cn = $res->{ FK_COLUMN_NAME };
                my $uk_tn = $res->{ UK_TABLE_NAME };
                my $uk_cn = $res->{ UK_COLUMN_NAME };
                eval { $self->_has_a_many( $fk_tn, $fk_cn, $uk_tn, $uk_cn) };
                warn qq/\# has_a_many failed "$@"\n\n/ if $@ && $self->debug;
           } 
        }
    }
}

sub kinships {
	my ($self, $class, $kind) = @_ ;
	return \%kinships unless $class;
	{ all      => $kinships{ $class } ,
	  has_a    => $kinships{ $class }{ has_a },
	  has_many => $kinships{ $class }{ has_many },
	  ''       => $kinships{ $class }
        }->{lc $kind||''};
}


1;

__END__

=head1 NAME

Class::DBI::Loader::Kinship - Fixes to Class::DBI::Loader 

=head1 SYNOPSIS

  use Class::DBI::Loader::Kinship;

  my $l = new Class::DBI::Loader::Kinship  (
                dsn           =>  $ENV{ DBI_DSN  },
                user          =>  $ENV{ DBI_USER },
                password      =>  $ENV{ DBI_PASS },
                namespace     =>  'music',
                exclude       =>  '^pg_.*|sql_.*',
  );

  my @tables  = $l->tables;
  my @classes = $l->classes;

  print Dumper $l->kinships;
  print Dumper $l->kinships('music::Cd');
  print Dumper $l->kinships('music::Cd', 'has_a');
  print Dumper $l->kinships('music::Cd', 'has_many');

=head1 DESCRIPTION

A subclass of Class::DBI::Loader which introduces the 3rd argument to
has_many relations, adds support to schemas for Postgresql, and
provides a few additional fuctions.  This package still dependends on its
subclass; and so far, I resisted to opt for cleaner code
and fork my own direction. The original Pg subclass is intentionally
prevented from loading so another can masquerade in its palace.


=head2 EXPORT

None by default.


=head1 SEE ALSO

L<Class::DBI::Loader>, L<Class::DBI::Loader::Pg>. 


=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Ioannis Tambouras

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
