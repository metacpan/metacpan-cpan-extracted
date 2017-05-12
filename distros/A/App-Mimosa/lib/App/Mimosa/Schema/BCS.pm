package App::Mimosa::Schema::BCS;
use strict;
use warnings;
#use Carp::Always;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces(
    result_namespace    => [
        'Result',
        '+Bio::Chado::Schema::Result::Organism',
      ],
    resultset_namespace => [
        'ResultSet',
        '+Bio::Chado::Schema::ResultSet::Organism',
      ],
  );


sub deploy {
    local $SIG{__WARN__} = sub {
        return if $_[0] =~ /^Ignoring relationship/;
        warn @_;
    };
    shift->SUPER::deploy(@_);
}

1;

__END__

=head1 NAME

App::Mimosa::Schema::BCS - DBIx::Class schema used by Mimosa.  A subset of Chado.

=head1 SYNOPSIS

  my $s = App::Mimosa::Schema::BCS->connect(...);

=head1 SEE ALSO

L<DBIx::Class>

=cut
