package Apache::FastForward;
# Copyright 2006 Jerzy Wachowiak

use strict;
use warnings;
use vars qw( $VERSION );
use Text::CSV_XS;
use Encode qw( resolve_alias encode decode);

use Apache;
@Apache::FastForward::ISA = qw( Apache );

$VERSION = '1.1'; 

# PUBLIC METHODS (convention: capital first letter)

sub new {

# Contract:
#   [1] Input: $r for mod_perl subclassing ('r' or '_r' magic name)

    my $class = shift;
    my $r = shift;
     
    my $self = {};
    $self->{VERSION} = $VERSION;
    $self->{r} = $r; 
    $self->{csv} = Text::CSV_XS->new( {
                    'quote_char'  => '"',
                    'escape_char' => '"',
                    'sep_char'    => ';',
                    'binary'      => 1 } ); # Needed by encoding of non ASCI characters!
    $self->{tables} = undef;    
    bless ( $self, $class );
    return $self
}

sub ParseBody {

# Contract:
#   [1] Input: Encoding (if nothing defaults to UTF-8)
#   [2] Output: returning success (1) or failure(0)

    my $self = shift;
    my $document_charset = shift;

    $document_charset = 'UTF-8' unless defined( $document_charset );
    resolve_alias( $document_charset ) or return 0;
    
    $self->read( my  $content, $self->header_in( 'Content-length' ) );    
    $content = decode( $document_charset, $content );
    
    my ( @variable_names, $header_key );  
    my @lines = split( /\n/, $content );
    for my $line ( @lines ){
      
        chomp( $line );
        next unless length( $line );
        
        if ( $self->{csv}->parse( $line ) ){
            my ( $steering_cell, @cells ) = $self->{csv}->fields();
            $steering_cell = lc( trim( $steering_cell ) );
        
            if ( $steering_cell eq 'post'){            
                
                undef( @variable_names );
                for my $cell ( @cells ){
                    $cell = trim( $cell )                  
                }                
                next if length( join( '', @cells ) ) == 0; 
                
                @variable_names = @cells;                                
                undef( $header_key );                
                $header_key = build_header_key( @variable_names );
                unless ( exists( $self->{tables}->{$header_key} ) ){                    
                    $self->{tables}->{$header_key} = undef                
                }
            }
            elsif ( $steering_cell eq 'value'){
            
                @variable_names or next;
            
                my %variable_value;
                my $index;
                for ( $index = 0; $index < scalar( @variable_names ); $index++ ){
                    my $value = $cells[$index];                    
                    if ( defined( $value ) ){
                        $value = trim( $value );
                        $variable_value{$variable_names[$index]} = $value  
                    }
                    else {
                        $variable_value{$variable_names[$index]} = undef
                    }                           
                }
                push( @{$self->{tables}->{$header_key}}, \%variable_value );                
            }
            else {
                next
            } #if ( $steering_cell eq 'post'){     
        }
        else {
            return 0
        } #if ( $self->{csv}->parse( $line ) ){        
    } #for my $line ( @lines ){
    return 1 
}

sub GetTable {

# Contract:
#   [1] Input: column names, order does not matter
#   [2] Output: array of hashes [ {col1=> var11, col2=>var12}, {col1=> var21, col2=>var22} ] 
#       or undef if nothing exists
    
    my ( $self, @column_headers ) = @_;

    my $header_key = build_header_key( @column_headers );
    if ( defined( $self->{tables}->{$header_key} ) ){
        return @{$self->{tables}->{$header_key}}
    }
    else {
        return undef
    }    
}

sub IsBodyEmpty {

# Contract:
#   [1] Input->no (parsed body is passed via the class instance)
#   [2] Output: check success (1) or failure(0)  
    
    my $self = shift;
    
    return not defined( $self->{tables} )
}

sub IsDefinedTable {

# Contract:
#   [1] Input: column names, order does not matter
#   [2] Output: check success (1) or failure(0)

    my ( $self, @column_headers ) = @_;

    my $header_key = build_header_key( @column_headers );
    
    return defined( $self->{tables}->{$header_key} )

}

sub IsDefinedHeader {

# Contract:
#   [1] Input: column names, order does not matter
#   [2] Output: check success (1) or failure(0)

    my ( $self, @column_headers ) = @_;

    my $header_key = build_header_key( @column_headers );
    
    return exists( $self->{tables}->{$header_key} )
}

sub ListHeaders {

# Contract:
#   [1] Input: last parsed body private via class instance 
#   [2] Output: array of headers or undef if nothing

    my $self = shift;

    return keys( %{$self->{tables}} )
}

sub ListTables {

# Contract:
#   [1] Input: last parsed body private via class instance 
#   [2] Output: array of headers or undef if nothing

    my $self = shift;

    my @tables;
    my @headers = keys( %{$self->{tables}} );
    foreach my $header ( @headers ){
	push( @tables, $header ) if $self->IsDefinedTable( $header )
    }
    
    return @tables
}


# PRIVATE METHODS (convention: small_letters) 

sub build_header_key{
  
    my @column_headers = @_;
        
    @column_headers = sort( @column_headers );
    my $header_key = join( '|', @column_headers );
      
    return $header_key    
}

sub trim {
    
    my $string =  shift;
    
    $string =~ s/^\s+//;
    $string =~s/\s+$//;
    
    return $string   
}
1
__END__
######################## User Documentation ##################

=pod

=head1 NAME

Apache::FastForward - new age of spreadsheet web services

=head1 SYNOPSIS

 package AAA::Demo;

 use Apache::Constants qw( :common );
 use Apache::FastForward;

 sub handler {
     
     my $r = Apache::FastForward->new( shift );
      
     my $user = $r->user();
     $r->send_http_header( 'text/plain' );
    
     $r->ParseBody();

     unless ( $r->IsDefinedTable( 'item', 'quantity' ) ){
            print 'Something went wrong...';
            return OK
     }

     my @item_quantity_table = $r->GetTable( 'item', 'quantity' );
     foreach my $row ( @item_quantity_table ){
          print $row->{item}}, $row->{quantity}
     }
 ...


=head1 DESCRIPTION


=head2 USAGE

The module is part of the FastForward project, which aim is to allow fast development of web based spreadsheet applications. Apache::FastForward implements receiving CSV formatted data by the POST request and their convenient manipulation on the server site. It solves similar problems as FORMS in the html. Apache::FastForward inherits from the Apache module (see L<Apache>). For more details please see L<http://fastforward.sourceforge.net>. 


=head2 METHODS

=over

=item ParseBody ( $encoding )

Parses the body of the POST request and stores inside the class instance. Encoding as input (if nothing defaults to UTF-8). Output: returning success (1) or failure(0).

=item GetTable ( $col1, $col2, $col3 )

Column names from the POST request (order does not matter). Output: array of hashes [ {col1=> var11, col2=>var12}, {col1=> var21, col2=>var22} ] or undef if nothing exists.

=item IsBodyEmpty ( )

Checks, if the POST body is empty. No input (valid for last parsed body - passed via the class instance). Output: body is empty->check success (1) or body is not empty-> failure(0). 

=item IsDefinedHeader ( $col1, $col2, $col3 )

Checks, if a set of column names (header) for a table is defined inside of the POST body. Column names as input (order does not matter).Output: check success (1) or failure(0).

=item IsDefinedTable ( $col1, $col2, $col3 )

Checks, if a table with the column names and some data is inside of the POST body. Column names as input (order does not matter - a set of column names defines a table).Output: check success (1) or failure(0).

=item ListHeaders ( )

No input (valid for last parsed body - passed via class instance). Output: array of headers (sets of column names defining a tables) or undef if nothing.

=item ListTables ( )

No input (valid for last parsed body - passed via class instance). Output: array of headers of tables (sets of column names defining a tables, where is some data inside) or undef if nothing.

=back

=head1 BUGS

Any suggestions for improvement are welcomed!

If a bug is detected or nonconforming behavior, 
please send an error report to <jwach@cpan.org>.

=head1 COPYRIGHT

Copyright 2006 Jerzy Wachowiak <jwach@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the terms of the Apache 2.0 license attached to the module.

=head1 SEE ALSO

L<Apache::FastForward::Spreadsheet>

=over
