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

package CBI::Wrapper::RIBA;

use warnings;
use strict;

use CBI::Wrapper::Record;
use CBI::Wrapper::Disposal;
use CBI::Wrapper::Flow;

# Create a RIBA flow with header, disposals and footer.
sub create_RIBA {
    my $args = shift;

	my $header    = $args->{header};
	my $disposals = $args->{disposals};

    	return unless (defined $header and defined $disposals);

	my $flow_type = 'RICEVUTE_BANCARIE';

	my $flow_CBI = new CBI::Wrapper::Flow();

	my $data_creazione = $header->{data_creazione};
	$data_creazione =~ /\d{2}(\d{2})-(\d{2})-(\d{2})/;
	$data_creazione = $3 . $2 . $1;

	my $header_CBI = &_create_record_CBI({
		fields =>
		{
			tipo_record          => 'IB',
			mittente             => $header->{mittente},
			ricevente            => $header->{ricevente},
			data_creazione       => $data_creazione,
			nome_supporto        => $header->{nome_supporto},
			campo_a_disposizione => $header->{campo_a_disposizione},
			tipo_flusso          => $header->{tipo_flusso},
			qualificatore_flusso => $header->{qualificatore_flusso},
			soggetto_veicolatore => $header->{soggetto_veicolatore},
			codice_divisa        => 'E',
		},
		flow_type => $flow_type,
	});
    $flow_CBI->set_header($header_CBI);

    # Set disposals and calculate footer values.
	my $i                    = 0;
	my $tot_importi_negativi = 0;
	my $num_records          = 2; # header + footer + num disposals.
	for my $disposal (@{$disposals}) {
		$i++;
		my $disposal_CBI = &_create_disposal_CBI_RIBA(
			{
				header             => $header,
				disposal           => $disposal,
				numero_progressivo => $i,
				flow_type 	   => $flow_type,
			},
		);
		$flow_CBI->append_disposal($disposal_CBI);
		$tot_importi_negativi += int((($disposal_CBI->get_record('14'))->get_field_content('importo')));
		$num_records += scalar @{$disposal_CBI->get_records()};
	}

	my $footer_CBI = &_create_record_CBI({
			fields =>
		{
			tipo_record          => 'EF',
			mittente             => $header->{mittente},
			ricevente            => $header->{ricevente},
            data_creazione       => $data_creazione,
			nome_supporto        => $header->{nome_supporto},
			numero_disposizioni  => $i,
			tot_importi_negativi => $tot_importi_negativi,
			tot_importi_positivi => 0,
			numero_record        => $num_records,
			codice_divisa        => $header->{codice_divisa},
		},
		flow_type => $flow_type,
	});

	$flow_CBI->set_footer($footer_CBI);

   	return $flow_CBI; 
}

# Create a disposal with records 14, 20, 30, 40, 50, 51, 70.  
sub _create_disposal_CBI_RIBA {
	my $args = shift;

	my $header          = $args->{header};
	my $disposal        = $args->{disposal};
	my $num_progressivo = $args->{numero_progressivo};
	my $flow_type     = $args->{flow_type};

	my $disposal_CBI = new CBI::Wrapper::Disposal();

    # Values conversion:
    # 	-> Currency from 0000.00 to 000000
    # 	-> Date from YYYY-MM-DD to DDMMYYYY
	my $importo = $disposal->{importo} * 100;    
	my $data    = $disposal->{data};             
	$data =~ /\d{2}(\d{2})-(\d{2})-(\d{2})/;
	$data = $3 . $2 . $1;

	my $record_CBI = &_create_record_CBI({ 
		fields =>
			{
			tipo_record                     => '14',
			numero_progressivo              => $num_progressivo,
			data_pagamento                  => $data,
			causale                         => '30000',
			importo                         => $importo,
			segno                           => '-',
			codice_abi_banca_assuntrice     => $disposal->{cod_abi_banca_assuntrice},
			cab_banca_assuntrice            => $disposal->{cab_banca_assuntrice},
			conto                           => $disposal->{conto},
			codice_abi_banca_domiciliataria => $disposal->{cod_abi_banca_domiciliataria},
			cab_banca_domiciliataria        => $disposal->{cab_banca_domiciliataria},
			codice_azienda                  => $disposal->{cod_azienda},
			tipo_codice                     => '4',
			codice_cliente_debitore         => $disposal->{cod_cliente_debitore},
			flag_tipo_debitore              => $disposal->{flag_tipo_debitore},
			codice_divisa                   => $header->{codice_divisa}
			},
		flow_type => $flow_type,
	});

	$disposal_CBI->append_record($record_CBI);

	$record_CBI = &_create_record_CBI({
		fields => 
		{
			tipo_record        => '20',
			numero_progressivo => $num_progressivo,
			'1_segmento'       => substr($disposal->{rag_soc_creditore},0,24),
            '2_segmento'       => length($disposal->{rag_soc_creditore}) > 24 ? substr($disposal->{rag_soc_creditore},24,24) : '', 
            '3_segmento'       => length($disposal->{rag_soc_creditore}) > 48 ? substr($disposal->{rag_soc_creditore},48,24) : '',
            '4_segmento'       => length($disposal->{rag_soc_creditore}) > 72 ? substr($disposal->{rag_soc_creditore},72,24) : '',
		},
		flow_type => $flow_type,
	});
	$disposal_CBI->append_record($record_CBI);

	$record_CBI = &_create_record_CBI({
		fields =>
		{
			tipo_record            => '30',
			numero_progressivo     => $num_progressivo,
			'1_segmento'           => substr($disposal->{nome_debitore},0,30), # Vedi tipo_record 20.
			'2_segmento'           => length($disposal->{nome_debitore}) > 30 ?  substr($disposal->{nome_debitore},30,30) : '',
			codice_fiscale_cliente => $disposal->{CF_debitore}
		},
		flow_type => $flow_type,
	});
	$disposal_CBI->append_record($record_CBI);
	
    $disposal->{comune_sigla_pv_debitore} =~ s/'//;
    $record_CBI = &_create_record_CBI({
		fields =>
		{
			tipo_record                => '40',
			numero_progressivo         => $num_progressivo,
			'indirizzo'                => $disposal->{indirizzo_debitore},
			'cap'                      => $disposal->{cap_debitore},
			'comune_e_sigla_provincia' => $disposal->{comune_sigla_pv_debitore},
			'completamento_indirizzo'  => $disposal->{compl_indirizzo},
		},
		flow_type => $flow_type,
	});
	$disposal_CBI->append_record($record_CBI);
	
    $record_CBI = &_create_record_CBI({
		fields =>
		{
			tipo_record                => '50',
			numero_progressivo         => $num_progressivo,
			'1_segmento'               => substr($disposal->{descrizione}, 0, 40), # Vedi tipo_record 20.
			'2_segmento'               => length($disposal->{descrizione}) > 40 ? substr($disposal->{descrizione}, 40, 40) : '',
			codifica_fiscale_creditore => $disposal->{PIVA_creditore}
		},
		flow_type => $flow_type,
	});
	$disposal_CBI->append_record($record_CBI);
	
    $record_CBI = &_create_record_CBI({
		fields =>
		{
			tipo_record             => '51',
			numero_progressivo      => $num_progressivo,
			numero_ricevuta         => $disposal->{numero_ricevuta},
			denominazione_creditore => $disposal->{denom_creditore},
			provincia_bollo         => $disposal->{provincia_bollo},
			numero_autorizzazione   => $disposal->{num_autorizzazione},
			data_autorizzazione     => $disposal->{data_autorizzazione}
		},
		flow_type => $flow_type,
	});
	$disposal_CBI->append_record($record_CBI);
	
    $record_CBI = &_create_record_CBI({
		    fields =>
		{
			tipo_record                  => '70',
			numero_progressivo           => $num_progressivo,
			indicatori_di_circuito       => $disposal->{indicatori_di_circuito},
			indicatore_richiesta_incasso => $disposal->{indicatore_richiesta_incasso},
			chiavi_di_controllo          => $disposal->{chiavi_di_controllo}
		},
		flow_type => $flow_type,
	});
	$disposal_CBI->append_record($record_CBI);
	
    return $disposal_CBI;
}

# Single line in the cbi flow.
sub _create_record_CBI {
	my $args = shift;

	my $fields = $args->{fields};
	my $flow_type = $args->{flow_type};

	my $record_CBI = new CBI::Wrapper::Record($fields->{tipo_record}, $flow_type);

	for my $key (keys %$fields) {
		$record_CBI->set_field_content($key, $fields->{$key});
	}

	return $record_CBI;
}

1;
