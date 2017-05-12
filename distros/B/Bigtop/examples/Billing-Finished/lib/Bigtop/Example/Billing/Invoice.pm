package Bigtop::Example::Billing::Invoice;

use strict;

use base 'Bigtop::Example::Billing::GEN::Invoice';

use PDF::API2;

use Gantry::Plugins::AutoCRUD qw(
    do_add
    do_edit
    do_delete
    form_name
);

use Bigtop::Example::Billing::Model::invoice qw(
    $INVOICE
);
use Bigtop::Example::Billing::Model;
use Bigtop::Example::Billing::Model::line_item qw( $LINE_ITEM );

sub schema_base_class { return 'Bigtop::Example::Billing::Model'; }
use Gantry::Plugins::DBIxClassConn qw( get_schema );
use Gantry::Plugins::Calendar qw(
    do_calendar_month
    calendar_month_js
);

#-----------------------------------------------------------------
# $self->do_pdf( $id )
#-----------------------------------------------------------------
sub do_pdf {
    my $self = shift;
#    $self->do_fake_pdf( @_ );
    $self->do_real_pdf( @_ );
}

#-----------------------------------------------------------------
# $self->do_fake_pdf( $id )
#-----------------------------------------------------------------
sub do_fake_pdf {
    my ( $self, $id ) = @_;

    # pull variables out of invoice row ready for here doc
    my $invoice     = $INVOICE->gfind( $self, $id );
    my $invoice_num = $invoice->number;
    my $sent        = $invoice->sent;
    my $description = $invoice->description || '';

    $description    = "\n$description\n" if $description;

    # my company data
    my %corp_data;

    foreach my $column qw( name address city state zip contact_phone ) {
        $corp_data{ $column } = $invoice->my_company->$column();
    }

    # customer data
    my %cust_data;
    foreach my $column
            qw( name address city state zip contact_phone contact_name )
    {
        $cust_data{ $column } = $invoice->customer->$column();
    }

    # tasks, pass the buck
    my ( $task_output, $total ) = $self->_task_output( $id );

    my $retval = << "EO_Invoice";
Billed By:
$corp_data{ name }
$corp_data{ address }
$corp_data{ city }, $corp_data{ state } $corp_data{ zip }
$corp_data{ contact_phone }

Billed To:
$cust_data{ name }
$cust_data{ address }
$cust_data{ city }, $cust_data{ state } $cust_data{ zip }
$cust_data{ contact_phone }
Attn: $cust_data{ contact_name }

Invoice Number: $invoice_num Invoice Date: $sent $description

Date         Hours    Rate/hr    Total   Task
$task_output
_______________________________________________________________________

Total Amount Due: $total

Invoice due upon receipt.
EO_Invoice

    $self->template_disable( 1 ); 		# turn off templating
    $self->content_type( 'text/plain' );

    return $retval;
}

sub _task_output {
    my ( $self, $id ) = @_;

    my @tasks = $LINE_ITEM->gsearch( $self, { invoice => $id } );

    my @rows;
    my $total       = 0;
    my $space       = ' ';

    foreach my $task ( @tasks ) {
        my $row_amount = $task->hours() * $task->charge_per_hour();

        $total        += $row_amount;

        my $row_output = $task->due_date()        . $space x 4;
        $row_output   .= $task->hours()           . $space x 8;
        $row_output   .= $task->charge_per_hour() . $space x 9;
        $row_output   .= $row_amount              . $space x 10;
        $row_output   .= $task->name();

        push @rows, $row_output;
    }
    my $task_output = join "\n", @rows;
    
    return $task_output, $total;
}

#-----------------------------------------------------------------
# $self->do_real_pdf( $id )
#-----------------------------------------------------------------
sub do_real_pdf {
    my ( $self, $id ) = @_;

    my $file;
    my $pdf_output;

    eval {
        my $invoice = $INVOICE->gfind( $self, $id );
        $file    = 'in' . $invoice->number . '.pdf';

        my $pdf  = new PDF::API2;

        my $font = $pdf->corefont('Times-Roman');
        my $page = $pdf->page;
        my $text = $page->text;

        my $dash_line = '_' x 85;

        # left header
        $text->font( $font,10 );
        $text->translate( 72, 728 );
        $text->text( $invoice->my_company->name );
        $text->translate( 72, 718 );
        $text->text( $invoice->my_company->address );
        $text->translate( 72, 708 );
        $text->text( $invoice->my_company->city . ', ' . 
                $invoice->my_company->state . ' ' . $invoice->my_company->zip
        );
        $text->translate( 72, 698 );
        $text->text( 'Tel: ' . $invoice->my_company->contact_phone );

        # Right side
        $text->translate( 400, 728 );
        $text->text('Invoice Date: ' . $invoice->sent() );

        $text->translate( 400, 718 );
        $text->text('Invoice Number: ' . $invoice->number );

        # line 400
        $text->font( $font,10 );
        $text->translate( 72, 680 );
        $text->text( $invoice->customer->name);
        $text->translate( 72, 670 );
        $text->text( $invoice->customer->address );
        $text->translate( 72, 660 );
        $text->text( $invoice->customer->city . ', ' . 
                $invoice->customer->state . ' ' . $invoice->customer->zip );

        $text->translate( 72, 650 );
        $text->text('Attention: ' . $invoice->customer->contact_name );
        $text->translate( 72, 640 );
        $text->text('Tel: ' . $invoice->customer->contact_phone );

        if ( $invoice->description ) {
            $text->translate( 240, 680 );
            $text->text( "Description:" );

            $text->translate( 240, 670 );
            $text->text( $invoice->description );
        }

        $text->font( $font,13 );	
        $text->translate( 275, 610 );
        $text->text('Invoice');
        $text->font( $font,10 );	

        $text->translate( 72, 607 );
        $text->text( $dash_line );

        my $total = 0;
        my $row = 595;

        $text->translate( 72, $row );
        $text->text( 'Date' );

        $text->translate( 172, $row );
        $text->text( 'Task' );

        $text->translate( 372, $row );
        $text->text( 'Hours' );

        $text->translate( 400, $row );
        $text->text( 'Per/Hour' );

        $text->translate( 445, $row );
        $text->text( 'Total' );	

        $row -= 8;
        $text->translate( 72, $row );
        $text->text( $dash_line );
        $row -= 12;

        my @tasks = $LINE_ITEM->gsearch( $self, { invoice => $id  } );

        foreach my $task ( @tasks ) {
            $text->translate( 72, $row );
            $text->text( $task->due_date );

            $text->translate( 172, $row );
            $text->text( $task->name );

            $text->translate( 372, $row );
            $text->text( $task->hours );

            $text->translate( 400, $row );
            $text->text( '$' . $task->charge_per_hour );

            $text->translate( 445, $row );
            $text->text( '$'
                    .  ( $task->hours * $task->charge_per_hour ) );

            $total += ( $task->hours * $task->charge_per_hour );
            $row -= 12;
        }

        if ( @tasks ) {
            $row -= 10;
            $text->font( $font,13 );			

            $text->translate( 360, $row );
            $text->text( 'Amount Due: ' );	

            $text->translate( 445, $row );
            $text->text( '$' . $total );	
        }
        $text->font( $font,10 );			
        $row -= 12;

        $text->translate( 360, $row );
        $text->text( '* Invoice due upon receipt' );

        $pdf_output = $pdf->stringify();
    };
    if ( $@ ) {
        die $@;
    }

    $self->template_disable( 1 ); 		# turn off templating
    $self->content_type( 'application/pdf' );

    $self->header_out(
            'Content-disposition' => "inline; filename=$file"
    );

    return $pdf_output;
} # END do_pdf

#-----------------------------------------------------------------
# $self->do_main(  )
#-----------------------------------------------------------------
sub do_main {
    my $self = shift;

    $self->SUPER::do_main();

    my $rows             = $self->stash->view->data()->{ rows };
    my $line_item_counts = $LINE_ITEM->get_count( $self );

    foreach my $row ( @{ $rows } ) {
        my $task_option = $row->{ options }[0];
        my $id          = ( split /\//, $task_option->{ link } )[-1];
        my $count       = $line_item_counts->{ $id } || 0;
        $task_option->{ text } .= " ($count)";
    }
}

#-----------------------------------------------------------------
# $self->form( $row )
#-----------------------------------------------------------------
# This method supplied by Bigtop::Example::Billing::GEN::Invoice


#-----------------------------------------------------------------
# get_model_name( )
#-----------------------------------------------------------------
sub get_model_name {
    return $INVOICE;
}

#-----------------------------------------------------------------
# get_orm_helper( )
#-----------------------------------------------------------------
sub get_orm_helper {
    return 'Gantry::Plugins::AutoCRUDHelper::DBIxClass';
}

#-----------------------------------------------------------------
# text_descr( )
#-----------------------------------------------------------------
sub text_descr     {
    return 'invoice';
}

1;

=head1 NAME

Bigtop::Example::Billing::Invoice - A controller in the Billing application

=head1 SYNOPSIS

This package is meant to be used in a stand alone server/CGI script or the
Perl block of an httpd.conf file.

Stand Alone Server or CGI script:

    use Bigtop::Example::Billing::Invoice;

    my $cgi = Gantry::Engine::CGI->new( {
        config => {
            #...
        },
        locations => {
            '/someurl' => 'Bigtop::Example::Billing::Invoice',
            #...
        },
    } );

httpd.conf:

    <Perl>
        # ...
        use Bigtop::Example::Billing::Invoice;
    </Perl>

    <Location /someurl>
        SetHandler  perl-script
        PerlHandler Bigtop::Example::Billing::Invoice
    </Location>

If all went well, one of these was correctly written during app generation.

=head1 DESCRIPTION

This module was originally generated by Bigtop.  But feel free to edit it.
You might even want to describe the table this module controls here.

=head1 METHODS

=over 4

=item do_pdf

=item get_model_name

=item text_descr

=item schema_base_class

=item get_orm_helper


=back


=head1 METHODS MIXED IN FROM Bigtop::Example::Billing::GEN::Invoice

=over 4

=item do_main

=item form


=back


=head1 DEPENDENCIES

    Bigtop::Example::Billing
    Bigtop::Example::Billing::GEN::Invoice
    Bigtop::Example::Billing::Model::invoice
    Gantry::Plugins::Calendar
    Gantry::Plugins::AutoCRUD

=head1 AUTHOR

Phil Crow

Tim Keefer

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
