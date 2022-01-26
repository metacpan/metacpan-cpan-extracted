##############################################################################
#
#    Copyright (C) 2022 Res Binaria Di Paolo Capaldo (<https://www.resbinaria.com/>)
#    All Rights Reserved
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published
#    by the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
##############################################################################

package CBI::Wrapper;

use warnings;
use strict;

our $VERSION = '0.02';

use CBI::Wrapper::RIBA;
use CBI::Wrapper::Flow;

sub new {
	my $class = shift;
	my $args  = shift;
	my $self  = {
		_header    => $args->{header},
		_disposals => $args->{disposals},
		_flow_CBI  => {},
	};

	bless $self, $class;

	return $self;
}

# Getters and Setters.

sub set_header {
	my ($self, $header) = @_;

	$self->{_header} = $header;
}

sub get_header {
	my ($self) = @_;

	return $self->{_header};
}

sub set_disposals {
	my ($self, $disposals) = @_;

	$self->{_disposals} = $disposals;
}

sub get_disposals {
	my ($self) = @_;

	return $self->{_disposals};
}

sub set_flow_CBI {
	my ($self, $flow_CBI) = @_;

	$self->{_flow_CBI} = $flow_CBI;
}

sub get_flow_CBI {
	my ($self) = @_;

	return $self->{_flow_CBI};
}

sub append_disposal {
	my ($self, $disposal) = @_;

	my $disposals = $self->get_disposals();
	push(@$disposals, $disposal);
	$self->set_disposals($disposals);
}

# Create a flow with header, disposals and footer.
sub create_flow {
	my ($self, $args) = @_;

	my $header    = defined $args->{header}    ? $args->{header}    : $self->get_header();
	my $disposals = defined $args->{disposals} ? $args->{disposals} : $self->get_disposals();

	return 0 unless (defined $header and defined $disposals);

	my $flow_type = defined $args->{flow_type} ? $args->{flow_type} : '';

	my $flow_CBI;

	if ($flow_type eq 'RICEVUTE_BANCARIE') {
		$flow_CBI = &CBI::Wrapper::RIBA::create_RIBA(
			{
				header    => $header,
				disposals => $disposals,
			}
		);
	}

	$self->set_flow_CBI($flow_CBI);

	return 1;
}

# Write CBI flow on file.
sub print {
	my ($self, $filename) = @_;

	return 0 unless defined $filename;

	my $flow_CBI = $self->get_flow_CBI();
	$flow_CBI->write_file($filename);
}

# Load CBI flow from file.
sub load {
	my ($self, $filename) = @_;

	my $flow_CBI = new CBI::Wrapper::Flow();

	$flow_CBI->read_file($filename);

	$self->set_flow_CBI($flow_CBI);
}

1;

__END__

=pod

=encoding latin1

=head1 NAME

CBI::Wrapper - Handle the Italian CBI fixed length file format.

=head1 VERSION

version 0.02

=head1 SYNOPSIS

Allow the handling of the Italian CBI fixed length
file format.
Core based on L<https://github.com/eLBati/CBI>.
This code is designed mainly to help writing "Ricevute bancarie (Ri.ba)"
data to files.

A typical usage is:

	use CBI::Wrapper;

	my $header = { ... };
	my $disposals = [{ ... }];

	my $cbi = new CBI::Wrapper({header => $header, disposals => $disposals});
	$cbi->create_flow({flow_type => 'RICEVUTE_BANCARIE'});
	$cbi->print('./outfile.cbi');

=head1 DESCRIPTION

C<CBI::Wrapper> is a Perl module that allow the handling of the Italian CBI
fixed length file format, mainly to write 
"Ricevute bancarie (Ri.ba)" data to files.

Features include:

=over 4

=item *

Creation of a flow from header and disposals data.

=item *

Write the desired data on cbi file.

=item *

Load a cbi file.

=back

B<Note:> For now only the Ri.ba format is supported.

=head1 LINKS

=over 4

=item *

L<Original Python code|https://github.com/eLBati/CBI>

=item *

L<Interbank Corporate Banking|https://www.cbi-org.eu/>

=back

=head1 CONSTRUCTOR AND STARTUP

=head2 new()

Creates and returns a new CBI::Wrapper object.
If the constructor is called without params, the content of header
and disposals won't be defined and you won't be able to create a flow.
You can:

=over 4

=item *

Pass params to the constructor:
	my $cbi = new CBI::Wrapper ({header => $header, disposals => $disposals});

=item *

Pass header and disposals as params to L</create_RIBA()>

=item *

Use the setters L</set_header({...})> and L</set_disposals([{...}])>

=back

=head1 SETTERS AND GETTERS

=head2 set_header($header)

Load the header passed as param.
This param is an hashref like this:

X<header_hashref>

	my $header = {
        	mittente             => '*****',        # SIA code sender
        	ricevente            => substr(IBAN_CREDITOR, 5, 5), # ABI code creditor
        	data_creazione       => 'YYYY-MM-DD',   # Creation date
        	nome_supporto        => '*****',        # Unique value
        	campo_a_disposizione => '',             # Can be empty
        	#  market place keys
        	tipo_flusso          => '',             # 
        	qualificatore_flusso => '',             # 
        	soggetto_veicolatore => '',             # ABI code Gateway bank       
        	codice_divisa        => 'E',            # currency E = euro
	};

=head2 get_header()

Return the current header hashref.

=head2 set_disposals($disposals)

Load the disposals passed as param.
This param is an arrayref containing the disposals
to insert in the flow.
This hashref is like this:

X<disposal_hashref>

	my $disposal = {
        	# Record 14 
        	data                            => 'YYYY-MM-DD', # due date
        	importo                         => EEEE.CC, # amount in Euro with two decimal numbers
        	cod_abi_banca_assuntrice        => substr(IBAN_CREDITOR, 5, 5),
        	cab_banca_assuntrice            => substr(IBAN_CREDITOR, 10, 5),
        	conto                           => substr(IBAN_CREDITOR, 15, 12),
        	cod_abi_banca_domiciliataria    => substr(IBAN_DEBTOR, 5, 5),
        	cab_banca_domiciliataria        => substr(IBAN_DEBTOR, 10, 5),
        	cod_azienda                     => '*****', # Same as 'mittente' in header.
        	cod_cliente_debitore            => '', # Debtor code private to the creditor (optional)
        	flag_tipo_debitore              => '', # 'B' if the debtor is a bank.

        	#Record 20
        	rag_soc_creditore               => '*****', # Creditor company name
        	indirizzo_creditore             => '*****', # Creditor address
        	cap_citta_creditore             => '*****', # Creditor ZIP code and city
        	rif_creditore                   => '*****', # Creditor other data

        	#30
        	nome_debitore                   => '*****', # Debtor name or company name
        	CF_debitore                     => '*****', # Debtor CF/PI

        	#40
        	indirizzo_debitore              => '*****', # Debtor address
        	cap_debitore                    => '*****', # Debtor ZIP code
        	comune_sigla_pv_debitore        => '*****', # Debtor city and province abbreviation
        	compl_indirizzo                 => '',

        	#50
        	descrizione                     => '*****', # Disposal description
        	PIVA_creditore                  => '*****', # Creditor PI

        	#51
        	numero_ricevuta                 => $i++, # Disposal number in flow
        	denom_creditore                 => substr($info_creditore->{ragione_sociale},0,20), # Creditor company name
        	provincia_bollo                 => '',
        	num_autorizzazione              => '',
       	 	data_autorizzazione             => '',

        	#70
        	indicatori_di_circuito          => '', # circuit markers
        	indicatore_richiesta_incasso    => '114', # document type + flag outcome notification + flag print nofication
        	chiavi_di_controllo             => '',  # control keys
	};

=head2 get_disposals()

Return the current disposals arrayref.

=head2 set_flow_CBI($CBI_flow)

Set the current CBI::Wrapper::Flow object.

=head2 get_flow_CBI()

Get the current CBI::Wrapper::Flow object.

=head2 append_disposal($disposal)

Append the L<disposal hashref|/disposal_hashref> passed as param to the current
disposals.

=head1 FLOW CREATION

=head2 create_flow()

Create a new flow from the current header and disposals.
If the current header or disposals are undefined, return 0.
You can set a new current header and disposals calling this
method with params like this:

	$cbi->create_flow({header => $header, 
			   disposals => $disposals, 
			   flow_type => $flow_type
	});

=head1 PRINTING AND LOADING FILES

=head2 print($filename)

Prints the current CBI::Wrapper::Flow object to a file
with the filename passed as param.
The current CBI::Wrapper::Flow object is defined when

=over 4

=item *

L</create_flow()> is called;

=item * 

a CBI::Wrapper::Flow is passed with L</set_flow_CBI($CBI_flow)>;

=item *

a file is L<loaded|/load($filename)>.

=back

=head2 load($filename)

Load a file with the filename passed as param.
This will set a new current CBI::Wrapper::Flow object
with the file content.
This will B<NOT> set the current header and disposals.

=head1 OTHER CBI FLOWS

You can configure other flows (es. MAV) editing CBI::Wrapper/RecordMapping.pm
In that file every disposal config is like this:

	my $IB = [
		{from => 1, to => 1, name => 'filler1', type => 'an', truncate =>  'no'},
	];
	
where

=over 4

=item *

from is the starting column

=item *

to is the ending column

=item *

type is the field data type (n = numeric, an = string)

=item *

truncate denotes if the string content will be truncated automatically (if length > field length)
or if an error will be thrown.

=back

=head1 ONLINE RESOURCES

=over 4

=item *

Official documentation L<https://www.cbi-org.eu/My-Menu/Servizio-CBI-Documentazione/Servizio-CBI-Documentazione-Standard>
(Registration required)

=back

=head1 ACKNOWLEDGEMENTS

Lorenzo Battistini - Author of the Python module from which this code is derived.

=head1 AUTHOR

Samuele Bonino <samuele.bonino at resbinaria.com>

=head1 COPYRIGHT AND LICENSE

	Copyright (C) 2022 Res Binaria Di Paolo Capaldo (<https://www.resbinaria.com/>)

	Original python code:
	Copyright (C) 2012 Agile Business Group sagl (<http://www.agilebg.com>)
	Copyright (C) 2012 Domsense srl (<http://www.domsense.com>)
	Copyright (C) 2012 Associazione OpenERP Italia

	All Rights Reserved

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU Affero General Public License as published
	by the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU Affero General Public License for more details.

	You should have received a copy of the GNU Affero General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

