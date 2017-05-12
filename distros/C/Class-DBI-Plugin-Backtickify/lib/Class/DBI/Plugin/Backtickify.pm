package Class::DBI::Plugin::Backtickify;

use warnings;
use strict;

use Class::ISA;

our $VERSION = 0.02;

=head1 NAME

Class::DBI::Plugin::Backtickify - surround column and table names with backticks

=head1 SYNOPSIS

    package Film;
    use base qw( Class::DBI ); 
    use Class::DBI::Plugin::Backtickify; # must come after the use base
    
=head1 DESCRIPTION

Puts backticks around table and column names. This allows reserved words to be used 
as column (and table?) names in MySQL (and others?). 

=head1 CAVEATS

It works by installing a C<transform_sql> method into your CDBI class. Other modules and 
plugins maybe do the same thing, in which case they may not play nicely with this. It does  
go through some hoops however to try and call other C<transform_sql> methods, but all the 
replacement tags will already have been removed so this might not help anyway. YMMV.

The installed C<transform_sql> finds column names using a regex over each C<@args> passed in. If 
strings matching column names (but not supposed to represent column names) exist as words 
in the input to the method, they will also get wrapped. Not sure how likely this is.

I haven't tested if this works with joins, but it should.

No tests yet.

=cut

sub import
{
    my ( $class ) = @_;
    
    my $caller = caller( 0 );
    
    no strict 'refs';
    *{"$caller\::transform_sql"} = \&transform_sql;
}

=head1 METHODS

=over 4

=item transform_sql

=back

=cut

sub transform_sql
{
    my ( $self, $sql, @args ) = @_;
    
    #warn "TRANSFORM_SQL: SQL IN:  $sql - @args\n";
    
    # Each entry in @args is a SQL fragment. This will bugger with fragments that 
    # contain strings that match column names but are not supposed to be column names. 
    my $backtickify_arg = sub { $_[0] =~ s/\b$_\b/`$_`/g for $self->all_columns };
    $backtickify_arg->( $_ ) for @args;
    
    # -------------------
    my %cmap;
    my $expand_table = sub {
        my ($class, $alias) = split /=/, shift, 2;
        my $table = $class ? $class->table : $self->table;
        $cmap{ $alias || $table } = $class || ref $self || $self;
        ($alias ||= "") &&= " AS `$alias`";
        return "`$table`$alias";
    };
        
    # -------------------
    my $expand_join = sub {
        my $joins  = shift;
        my @table  = split /\s+/, $joins;
        my %tojoin = map { $table[$_] => $table[ $_ + 1 ] } 0 .. $#table - 1;
        my @sql;
        while (my ($t1, $t2) = each %tojoin) {
                my ($c1, $c2) = map $cmap{$_}
                        || $self->_croak("Don't understand table '$_' in JOIN"), ($t1, $t2);

                my $join_col = sub {
                        my ($c1, $c2) = @_;
                        my $meta = $c1->meta_info('has_a');
                        my ($col) = grep $meta->{$_}->foreign_class eq $c2, keys %$meta;
                        $col;
                };

                my $col = $join_col->($c1 => $c2) || do {
                        ($c1, $c2) = ($c2, $c1);
                        ($t1, $t2) = ($t2, $t1);
                        $join_col->($c1 => $c2);
                };

                $self->_croak("Don't know how to join $c1 to $c2") unless $col;
                push @sql, sprintf " `%s`.`%s` = `%s`.`%s` ", $t1, $col, $t2,
                        $c2->primary_column;
        }
        return join " AND ", @sql;
    };
    
    # -------------------
    $sql =~ s/__TABLE\(?(.*?)\)?__/$expand_table->($1)/eg;
    $sql =~ s/__JOIN\((.*?)\)__/$expand_join->($1)/eg;
    $sql =~ s/__ESSENTIAL__/join ", ", map { "`$_`" } $self->_essential/eg;
    $sql =~ s/__ESSENTIAL\((.*?)\)__/join ", ", map { "`$1`.`$_`" } $self->_essential/eg;    
    
    if ( $sql =~ /__IDENTIFIER__/ ) 
    {
        my $key_sql = join " AND ", map "`$_`=?", $self->primary_columns;
        $sql =~ s/__IDENTIFIER__/$key_sql/g;
    }
    
    # nasty hack
    my $super = ( Class::ISA::super_path( ref( $self ) || $self ) )[0];
    
    my $eval = '{ package %s; $self->SUPER::transform_sql( q(%s), ';
    $eval .= 'q(%s), ' for @args;
    $eval .= ') }';
    
    my $return = eval sprintf $eval, $super, $sql, @args;
    
    die $@ if $@;
    
    return $return;

    #my $out = $self->SUPER::transform_sql($sql => @args);
    #warn "TRANSFORM_SQL: SQL OUT: $out\n";
    #return $out;
}


=head1 AUTHOR

David Baird, C<< <cpan@riverside-cms.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-dbi-plugin-backtickify@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-DBI-Plugin-Backtickify>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 David Baird, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Class::DBI::Plugin::Backtickify
