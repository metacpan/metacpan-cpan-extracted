use warnings;
use strict;

package DBD::PassThrough;
use 5.008005;
our $VERSION = '0.02';

{
    package DBD::PassThrough;
    require DBI;
    DBI->require_version(1.0201);

    our $drh = undef;       # holds driver handle(s) once initialized
    our $imp_data_size = 0;

    sub driver($;$) {
        my ($class, $attr) = @_;
        $drh->{$class} and return $drh->{$class}; # Is this line needed?

        $attr ||= +{};
        $attr->{Attribution} ||= __PACKAGE__ . ' by tokuhirom';
        $attr->{Version} ||= $VERSION;
        $attr->{Name} ||= 'PassThrough';

        # Make delegater methods
        # This is needed like '$dbh->func("last_insert_rowid")'
        {
            my %drivers = DBI->installed_drivers;
            no strict 'refs';
            for my $db_class (keys %drivers) {
                my @meth = grep !/^[_A-Z]/, keys %{"DBD::${db_class}::db::"};
                for my $meth (sort @meth) {
                    next if DBD::PassThrough::db->can($meth);
                    *{"DBD::PassThrough::db::${meth}"} = sub {
                        my $dbh = shift;
                        return $dbh->{pass_through_source}->func($meth => @_);
                    };
                }
            }
        }

        $drh->{$class} = DBI::_new_drh( $class . "::dr", $attr );
        return $drh->{$class};
    }
}

{
    package DBD::PassThrough::dr;
    our $imp_data_size = 0;
}

{
    package DBD::PassThrough::db;
    our $imp_data_size = 0;
    sub STORE {
        my ($dbh, $attrib, $value) = @_;
        if ($dbh->{pass_through_source}) {
            return $dbh->{pass_through_source}->STORE($attrib, $value);
        }
        if ($attrib eq 'pass_through_source') {
            $dbh->{pass_through_source} = $value;
            return;
        }
        return $dbh->set_err($DBI::stderr, "Can't alter \$dbh->{$attrib} after handle created with DBD::PassThrough");
    }
    sub FETCH {
        my ($dbh, $attrib) = @_;
        if ($attrib eq 'pass_through_source') {
            return $dbh->{pass_through_source};
        }
        if ($dbh->{pass_through_source}) {
            return $dbh->{pass_through_source}->FETCH($attrib);
        }
        if ($attrib eq 'Active') {
            return 0; # pass_through_source is not set yet.
        }
        return $dbh->set_err($DBI::stderr, "Can't fetch \$dbh->{$attrib} before connect with DBD::PassThrough");
    }
    
    # do not disconnect parent handle.
    sub disconnect {
        my $dbh = shift;
        delete $dbh->{pass_through_source};
        return 1;
    }

    # Generate methods
    for my $meth (qw(prepare table_info get_info type_info_all type_info column_info primary_key_info primary_key foreign_key_info tables quote quote_identifier)) {
        no strict 'refs';
        *{"DBD::PassThrough::db::${meth}"} = sub {
            my $dbh = shift;
            return $dbh->{pass_through_source}->$meth(@_);
        };
    }
}

1;
__END__

=encoding utf8

=head1 NAME

DBD::PassThrough - Pass through DBD

=head1 SYNOPSIS

    use DBI;

    my $orig_dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    my $dbh = DBI->connect('dbi:PassThrough:', '', '', {pass_through_source => $orig_dbh});

=head1 DESCRIPTION

DBD::PassThrough is a proxy module betwen DSN to $dbh.

You can pass a existed $dbh as a new DBI connection's atribute.

B<THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE>.

=head1 WHY?

Some of the DBIx::* modules do not accepts $dbh as a argument, but arguments for C<< DBI->connect >>.
Then, it makes hard to use DBD::SQLite as a mock DB.

=head2 SCENARIO

=over 4

=item I want to use DBD::SQLite's on memory database.

=item I need to prepare on memory database(CREATE TABLEs, etc.)

=item But DBIx::FooBar module does not accepts $dbh.

=item Then, I need DBD::PassThrough.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
