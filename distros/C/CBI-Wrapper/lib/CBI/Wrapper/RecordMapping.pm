##############################################################################
#       
#    Copyright (C) 2012 Agile Business Group sagl (<http://www.agilebg.com>)
#    Copyright (C) 2012 Domsense srl (<http://www.domsense.com>)
#    Copyright (C) 2012 Associazione OpenERP Italia
#    (<http://www.openerp-italia.org>).
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

package CBI::Wrapper::RecordMapping;

use strict;
use warnings;

# Cfg file.

our $FLOW_TYPE = 'OUTPUT_RECORD_MAPPING';    # default value

# Header 'IB'
my $IB = [
	{from => 1,   to => 1,   name => 'filler1',               type => 'an', truncate =>  'no'},
	{from => 2,   to => 3,   name => 'tipo_record',           type => 'an', truncate =>  'no'},
	{from => 4,   to => 8,   name => 'mittente',              type => 'an', truncate =>  'no'},
	{from => 9,   to => 13,  name => 'ricevente',             type => 'n',  truncate =>  'no'},
	{from => 14,  to => 19,  name => 'data_creazione',        type => 'n',  truncate =>  'no'},
	{from => 20,  to => 39,  name => 'nome_supporto',         type => 'an', truncate =>  'no'},
	{from => 40,  to => 45,  name => 'campo_a_disposizione',  type => 'an', truncate =>  'no'},
	{from => 46,  to => 104, name => 'filler2',               type => 'an', truncate =>  'no'},
	{from => 105, to => 105, name => 'tipo_flusso',           type => 'an', truncate =>  'no'},
	{from => 106, to => 106, name => 'qualificatore_flusso',  type => 'an', truncate =>  'no'},
	{from => 107, to => 111, name => 'soggetto_veicolatore',  type => 'n',  truncate =>  'no'},
	{from => 112, to => 113, name => 'filler3',               type => 'an', truncate =>  'no'},
	{from => 114, to => 114, name => 'codice_divisa',         type => 'an', truncate =>  'no'},
	{from => 115, to => 115, name => 'filler4',               type => 'an', truncate =>  'no'},
	{from => 116, to => 120, name => 'campo_non_disponibile', type => 'an', truncate =>  'no'},
];


# Header 'IM'
my $IM = [
	{from => 1,   to => 1,   name => 'filler1',               type => 'an', truncate =>  'no'},
	{from => 2,   to => 3,   name => 'tipo_record',           type => 'an', truncate =>  'no'},
	{from => 4,   to => 8,   name => 'mittente',              type => 'an', truncate =>  'no'},
	{from => 9,   to => 13,  name => 'ricevente',             type => 'an', truncate =>  'no'},
	{from => 14,  to => 19,  name => 'data_creazione',        type => 'an', truncate =>  'no'},
	{from => 20,  to => 39,  name => 'nome_supporto',         type => 'an', truncate =>  'no'},
	{from => 40,  to => 45,  name => 'campo_a_disposizione',  type => 'an', truncate =>  'no'},
	{from => 46,  to => 104, name => 'filler2',               type => 'an', truncate =>  'no'},
	{from => 105, to => 105, name => 'tipo_flusso',           type => 'an', truncate =>  'no'},
	{from => 106, to => 106, name => 'qualificatore_flusso',  type => 'an', truncate =>  'no'},
	{from => 107, to => 111, name => 'soggetto_veicolatore',  type => 'an', truncate =>  'no'},
	{from => 112, to => 113, name => 'filler3',               type => 'an', truncate =>  'no'},
	{from => 114, to => 114, name => 'codice_divisa',         type => 'an', truncate =>  'no'},
	{from => 115, to => 115, name => 'filler4',               type => 'an', truncate =>  'no'},
	{from => 116, to => 120, name => 'campo_non_disponibile', type => 'an', truncate =>  'no'},
];

# Header 'PC'
my $PC = [
	{from => 1,   to => 1,   name => 'filler1',                            type => 'an', truncate =>  'no'},
	{from => 2,   to => 3,   name => 'tipo_record',                        type => 'an', truncate =>  'no'},
	{from => 4,   to => 8,   name => 'mittente',                           type => 'an', truncate =>  'no'},
	{from => 9,   to => 13,  name => 'ricevente',                          type => 'an', truncate =>  'no'},
	{from => 14,  to => 19,  name => 'data_creazione',                     type => 'an', truncate =>  'no'},
	{from => 20,  to => 39,  name => 'nome_supporto',                      type => 'an', truncate =>  'no'},
	{from => 40,  to => 45,  name => 'campo_a_disposizione',               type => 'an', truncate =>  'no'},
	{from => 46,  to => 104, name => 'filler2',                            type => 'an', truncate =>  'no'},
	{from => 105, to => 105, name => 'tipo_flusso',                        type => 'an', truncate =>  'no'},
	{from => 106, to => 106, name => 'qualificatore_flusso',               type => 'an', truncate =>  'no'},
	{from => 107, to => 111, name => 'soggetto_veicolatore',               type => 'an', truncate =>  'no'},
	{from => 112, to => 112, name => 'filler3',                            type => 'an', truncate =>  'no'},
	{from => 113, to => 113, name => 'flag_priorita_trattamento_bonifico', type => 'an', truncate =>  'no'},
	{from => 114, to => 114, name => 'codice_divisa',                      type => 'an', truncate =>  'no'},
	{from => 115, to => 115, name => 'filler4',                            type => 'an', truncate =>  'no'},
	{from => 116, to => 120, name => 'campo_non_disponibile',              type => 'an', truncate =>  'no'},
];

# Header 'PE'
my $PE = [
	{from => 1,   to => 1,   name => 'filler1',               type => 'an', truncate =>  'no'},
	{from => 2,   to => 3,   name => 'tipo_record',           type => 'an', truncate =>  'no'},
	{from => 4,   to => 8,   name => 'mittente',              type => 'an', truncate =>  'no'},
	{from => 9,   to => 13,  name => 'ricevente',             type => 'an', truncate =>  'no'},
	{from => 14,  to => 19,  name => 'data_creazione',        type => 'an', truncate =>  'no'},
	{from => 20,  to => 39,  name => 'nome_supporto',         type => 'an', truncate =>  'no'},
	{from => 40,  to => 45,  name => 'campo_a_disposizione',  type => 'an', truncate =>  'no'},
	{from => 46,  to => 104, name => 'filler2',               type => 'an', truncate =>  'no'},
	{from => 105, to => 105, name => 'tipo_flusso',           type => 'an', truncate =>  'no'},
	{from => 106, to => 106, name => 'qualificatore_flusso',  type => 'an', truncate =>  'no'},
	{from => 107, to => 111, name => 'soggetto_veicolatore',  type => 'an', truncate =>  'no'},
	{from => 112, to => 115, name => 'filler3',               type => 'an', truncate =>  'no'},
	{from => 116, to => 120, name => 'campo_non_disponibile', type => 'an', truncate =>  'no'},
];

# Footer 'EF'
my $EF = [
	{from => 1,   to => 1,   name => 'filler1',               type => 'an', truncate =>  'no'},
	{from => 2,   to => 3,   name => 'tipo_record',           type => 'an', truncate =>  'no'},
	{from => 4,   to => 8,   name => 'mittente',              type => 'an', truncate =>  'no'},
	{from => 9,   to => 13,  name => 'ricevente',             type => 'n',  truncate =>  'no'},
	{from => 14,  to => 19,  name => 'data_creazione',        type => 'n',  truncate =>  'no'},
	{from => 20,  to => 39,  name => 'nome_supporto',         type => 'an', truncate =>  'no'},
	{from => 40,  to => 45,  name => 'campo_a_disposizione',  type => 'an', truncate =>  'no'},
	{from => 46,  to => 52,  name => 'numero_disposizioni',   type => 'n',  truncate =>  'no'},
	{from => 53,  to => 67,  name => 'tot_importi_negativi',  type => 'n',  truncate =>  'no'},
	{from => 68,  to => 82,  name => 'tot_importi_positivi',  type => 'n',  truncate =>  'no'},
	{from => 83,  to => 89,  name => 'numero_record',         type => 'n',  truncate =>  'no'},
	{from => 90,  to => 113, name => 'filler2',               type => 'an', truncate =>  'no'},
	{from => 114, to => 114, name => 'codice_divisa',         type => 'an', truncate =>  'no'},
	{from => 115, to => 120, name => 'campo_non_disponibile', type => 'an', truncate =>  'no'},
];

# Footer 'EF' - bonifici
my $EF_BON = [
	{from => 1,   to => 1,   name => 'filler1',                            type => 'an', truncate =>  'no'},
	{from => 2,   to => 3,   name => 'tipo_record',                        type => 'an', truncate =>  'no'},
	{from => 4,   to => 8,   name => 'mittente',                           type => 'an', truncate =>  'no'},
	{from => 9,   to => 13,  name => 'ricevente',                          type => 'an', truncate =>  'no'},
	{from => 14,  to => 19,  name => 'data_creazione',                     type => 'an', truncate =>  'no'},
	{from => 20,  to => 39,  name => 'nome_supporto',                      type => 'an', truncate =>  'no'},
	{from => 40,  to => 45,  name => 'campo_a_disposizione',               type => 'an', truncate =>  'no'},
	{from => 46,  to => 52,  name => 'numero_disposizioni',                type => 'an', truncate =>  'no'},
	{from => 53,  to => 67,  name => 'tot_importi_negativi',               type => 'an', truncate =>  'no'},
	{from => 68,  to => 82,  name => 'tot_importi_positivi',               type => 'an', truncate =>  'no'},
	{from => 83,  to => 89,  name => 'numero_record',                      type => 'an', truncate =>  'no'},
	{from => 90,  to => 112, name => 'filler2',                            type => 'an', truncate =>  'no'},
	{from => 113, to => 113, name => 'flag_priorita_trattamento_bonifico', type => 'an', truncate =>  'no'},
	{from => 114, to => 114, name => 'codice_divisa',                      type => 'an', truncate =>  'no'},
	{from => 115, to => 120, name => 'campo_non_disponibile',              type => 'an', truncate =>  'no'},
];

# Footer 'EF' - bonifici esteri
my $EF_BON_ES = [
	{from => 1,   to => 1,   name => 'filler1',               type => 'an', truncate =>  'no'},
	{from => 2,   to => 3,   name => 'tipo_record',           type => 'an', truncate =>  'no'},
	{from => 4,   to => 8,   name => 'mittente',              type => 'an', truncate =>  'no'},
	{from => 9,   to => 13,  name => 'ricevente',             type => 'an', truncate =>  'no'},
	{from => 14,  to => 19,  name => 'data_creazione',        type => 'an', truncate =>  'no'},
	{from => 20,  to => 39,  name => 'nome_supporto',         type => 'an', truncate =>  'no'},
	{from => 40,  to => 45,  name => 'campo_a_disposizione',  type => 'an', truncate =>  'no'},
	{from => 46,  to => 52,  name => 'numero_disposizioni',   type => 'an', truncate =>  'no'},
	{from => 53,  to => 64,  name => 'filler2',               type => 'an', truncate =>  'no'},
	{from => 65,  to => 82,  name => 'totale_importi',        type => 'an', truncate =>  'no'},
	{from => 83,  to => 89,  name => 'numero_record',         type => 'an', truncate =>  'no'},
	{from => 90,  to => 114, name => 'filler3',               type => 'an', truncate =>  'no'},
	{from => 115, to => 120, name => 'campo_non_disponibile', type => 'an', truncate =>  'no'},
];

# Record “10”
my $X = [
	{from => 1,   to => 1,   name => 'filler1',                            type => 'an', truncate =>  'no'},
	{from => 2,   to => 3,   name => 'tipo_record',                        type => 'an', truncate =>  'no'},
	{from => 4,   to => 10,  name => 'numero_progressivo',                 type => 'an', truncate =>  'no'},
	{from => 11,  to => 16,  name => 'filler2',                            type => 'an', truncate =>  'no'},
	{from => 17,  to => 22,  name => 'data_esecuzione_disposizione',       type => 'an', truncate =>  'no'},
	{from => 23,  to => 28,  name => 'data_valuta_banca_beneficiario',     type => 'an', truncate =>  'no'},
	{from => 29,  to => 33,  name => 'causale',                            type => 'an', truncate =>  'no'},
	{from => 34,  to => 46,  name => 'importo',                            type => 'an', truncate =>  'no'},
	{from => 47,  to => 47,  name => 'segno',                              type => 'an', truncate =>  'no'},
	{from => 48,  to => 52,  name => 'codice_abi_banca_ordinante',         type => 'an', truncate =>  'no'},
	{from => 53,  to => 57,  name => 'codice_cab_banca_ordinante',         type => 'an', truncate =>  'no'},
	{from => 58,  to => 69,  name => 'conto_ordinante',                    type => 'an', truncate =>  'no'},
	{from => 70,  to => 74,  name => 'codice_abi_banca_destinataria',      type => 'an', truncate =>  'no'},
	{from => 75,  to => 79,  name => 'codice_cab_banca_destinataria',      type => 'an', truncate =>  'no'},
	{from => 80,  to => 91,  name => 'conto_destinatario',                 type => 'an', truncate =>  'no'},
	{from => 92,  to => 96,  name => 'codice_azienda',                     type => 'an', truncate =>  'no'},
	{from => 97,  to => 97,  name => 'tipo_codice',                        type => 'an', truncate =>  'no'},
	{from => 98,  to => 113, name => 'codice_cliente_beneficiario',        type => 'an', truncate =>  'no'},
	{from => 114, to => 114, name => 'modalita_di_pagamento',              type => 'an', truncate =>  'no'},
	{from => 115, to => 118, name => 'filler4',                            type => 'an', truncate =>  'no'},
	{from => 119, to => 119, name => 'flag_priorita_trattamento_bonifico', type => 'an', truncate =>  'no'},
	{from => 120, to => 120, name => 'codice_divisa',                      type => 'an', truncate =>  'no'},
];

# Record “14”
my $XIV = [
	{from => 1,   to => 1,   name => 'filler1',                         type => 'an', truncate =>  'no'},
	{from => 2,   to => 3,   name => 'tipo_record',                     type => 'an', truncate =>  'no'},
	{from => 4,   to => 10,  name => 'numero_progressivo',              type => 'n',  truncate =>  'no'},
	{from => 11,  to => 22,  name => 'filler2',                         type => 'an', truncate =>  'no'},
	{from => 23,  to => 28,  name => 'data_pagamento',                  type => 'n',  truncate =>  'no'},
	{from => 29,  to => 33,  name => 'causale',                         type => 'n',  truncate =>  'no'},
	{from => 34,  to => 46,  name => 'importo',                         type => 'n',  truncate =>  'no'},
	{from => 47,  to => 47,  name => 'segno',                           type => 'an', truncate =>  'no'},
	{from => 48,  to => 52,  name => 'codice_abi_banca_assuntrice',     type => 'n',  truncate =>  'no'},
	{from => 53,  to => 57,  name => 'cab_banca_assuntrice',            type => 'n',  truncate =>  'no'},
	{from => 58,  to => 69,  name => 'conto',                           type => 'an', truncate =>  'no'},
	{from => 70,  to => 74,  name => 'codice_abi_banca_domiciliataria', type => 'n',  truncate =>  'no'},
	{from => 75,  to => 79,  name => 'cab_banca_domiciliataria',        type => 'n',  truncate =>  'no'},
	{from => 80,  to => 91,  name => 'filler3',                         type => 'an', truncate =>  'no'},
	{from => 92,  to => 96,  name => 'codice_azienda',                  type => 'an', truncate =>  'no'},
	{from => 97,  to => 97,  name => 'tipo_codice',                     type => 'n',  truncate =>  'no'},
	{from => 98,  to => 113, name => 'codice_cliente_debitore',         type => 'an', truncate =>  'no'},
	{from => 114, to => 114, name => 'flag_tipo_debitore',              type => 'an', truncate =>  'no'},
	{from => 115, to => 119, name => 'filler4',                         type => 'an', truncate =>  'no'},
	{from => 120, to => 120, name => 'codice_divisa',                   type => 'an', truncate =>  'no'},
];

# Record 16 [coordinate ordinante]
my $XVI = [
	{from => 1,  to => 1,   name => 'filler1',            type => 'an', truncate =>  'no'},
	{from => 2,  to => 3,   name => 'tipo_record',        type => 'an', truncate =>  'no'},
	{from => 4,  to => 10,  name => 'numero_progressivo', type => 'an', truncate =>  'no'},
	{from => 11, to => 12,  name => 'codice_paese',       type => 'an', truncate =>  'no'},
	{from => 13, to => 14,  name => 'check_digit',        type => 'an', truncate =>  'no'},
	{from => 15, to => 15,  name => 'cin',                type => 'an', truncate =>  'no'},
	{from => 16, to => 20,  name => 'codice_abi',         type => 'an', truncate =>  'no'},
	{from => 21, to => 25,  name => 'codice_cab',         type => 'an', truncate =>  'no'},
	{from => 26, to => 37,  name => 'numero_conto',       type => 'an', truncate =>  'no'},
	{from => 38, to => 44,  name => 'filler2',            type => 'an', truncate =>  'no'},
	{from => 45, to => 120, name => 'filler3',            type => 'an', truncate =>  'no'},
];

# Record “17” [coordinate beneficiario]
my $XVII = [
	{from => 1,  to => 1,   name => 'filler1',            type => 'an', truncate =>  'no'},
	{from => 2,  to => 3,   name => 'tipo_record',        type => 'an', truncate =>  'no'},
	{from => 4,  to => 10,  name => 'numero_progressivo', type => 'an', truncate =>  'no'},
	{from => 11, to => 12,  name => 'codice_paese',       type => 'an', truncate =>  'no'},
	{from => 13, to => 14,  name => 'check_digit',        type => 'an', truncate =>  'no'},
	{from => 15, to => 15,  name => 'cin',                type => 'an', truncate =>  'no'},
	{from => 16, to => 20,  name => 'codice_abi',         type => 'an', truncate =>  'no'},
	{from => 21, to => 25,  name => 'codice_cab',         type => 'an', truncate =>  'no'},
	{from => 26, to => 37,  name => 'numero_conto',       type => 'an', truncate =>  'no'},
	{from => 38, to => 44,  name => 'filler2',            type => 'an', truncate =>  'no'},
	{from => 45, to => 120, name => 'filler3',            type => 'an', truncate =>  'no'},
];

# Record “20”
my $XX = [
	{from => 1,   to => 1,   name => 'filler1',            type => 'an', truncate =>  'no'},
	{from => 2,   to => 3,   name => 'tipo_record',        type => 'an', truncate =>  'no'},
	{from => 4,   to => 10,  name => 'numero_progressivo', type => 'n',  truncate =>  'no'},
	{from => 11,  to => 34,  name => '1_segmento',         type => 'an', truncate =>  'yes'},
	{from => 35,  to => 58,  name => '2_segmento',         type => 'an', truncate =>  'yes'},
	{from => 59,  to => 82,  name => '3_segmento',         type => 'an', truncate =>  'yes'},
	{from => 83,  to => 106, name => '4_segmento',         type => 'an', truncate =>  'yes'},
	{from => 107, to => 120, name => 'filler2',            type => 'an', truncate =>  'no'},
];

# Record “20” - bonifici
my $XX_BON = [
	{from => 1,   to => 1,   name => 'filler1',               type => 'an', truncate =>  'no'},
	{from => 2,   to => 3,   name => 'tipo_record',           type => 'an', truncate =>  'no'},
	{from => 4,   to => 10,  name => 'numero_progressivo',    type => 'an', truncate =>  'no'},
	{from => 11,  to => 40,  name => 'denominazione_azienda', type => 'an', truncate =>  'no'},
	{from => 41,  to => 70,  name => 'indirizzo',             type => 'an', truncate =>  'no'},
	{from => 71,  to => 100, name => 'localita',              type => 'an', truncate =>  'no'},
	{from => 101, to => 116, name => 'codifica_fiscale',      type => 'an', truncate =>  'no'},
	{from => 117, to => 120, name => 'filler2',               type => 'an', truncate =>  'no'},
];

# Record “30”
my $XXX = [
	{from => 1,  to => 1,   name => 'filler1',                type => 'an', truncate =>  'no'},
	{from => 2,  to => 3,   name => 'tipo_record',            type => 'an', truncate =>  'no'},
	{from => 4,  to => 10,  name => 'numero_progressivo',     type => 'n',  truncate =>  'no'},
	{from => 11, to => 40,  name => '1_segmento',             type => 'an', truncate =>  'yes'},
	{from => 41, to => 70,  name => '2_segmento',             type => 'an', truncate =>  'yes'},
	{from => 71, to => 86,  name => 'codice_fiscale_cliente', type => 'an', truncate =>  'no'},
	{from => 87, to => 120, name => 'filler2',                type => 'an', truncate =>  'no'},
];

# Record “30” - bonifici
my $XXX_BON = [
	{from => 1,   to => 1,   name => 'filler1',                type => 'an', truncate =>  'no'},
	{from => 2,   to => 3,   name => 'tipo_record',            type => 'an', truncate =>  'no'},
	{from => 4,   to => 10,  name => 'numero_progressivo',     type => 'an', truncate =>  'no'},
	{from => 11,  to => 40,  name => '1_segmento',             type => 'an', truncate =>  'no'},
	{from => 41,  to => 70,  name => '2_segmento',             type => 'an', truncate =>  'no'},
	{from => 71,  to => 100, name => '3_segmento',             type => 'an', truncate =>  'no'},
	{from => 101, to => 116, name => 'codice_fiscale_cliente', type => 'an', truncate =>  'no'},
	{from => 117, to => 120, name => 'filler2',                type => 'an', truncate =>  'no'},
];

# Record “40”
my $XL = [
	{from => 1,  to => 1,   name => 'filler1',                  type => 'an', truncate =>  'no'},
	{from => 2,  to => 3,   name => 'tipo_record',              type => 'an', truncate =>  'no'},
	{from => 4,  to => 10,  name => 'numero_progressivo',       type => 'n',  truncate =>  'no'},
	{from => 11, to => 40,  name => 'indirizzo',                type => 'an', truncate =>  'yes'},
	{from => 41, to => 45,  name => 'cap',                      type => 'n',  truncate =>  'no'},
	{from => 46, to => 70,  name => 'comune_e_sigla_provincia', type => 'an', truncate =>  'yes'},
	{from => 71, to => 120, name => 'completamento_indirizzo',  type => 'an', truncate =>  'yes'}, # Eventuale denominazione in chiaro della banca/sportello
                                                                                                    # domiciliataria/o.
];

# Record “40” - bonifici
my $XL_BON = [
	{from => 1,  to => 1,   name => 'filler1',                      type => 'an', truncate =>  'no'},
	{from => 2,  to => 3,   name => 'tipo_record',                  type => 'an', truncate =>  'no'},
	{from => 4,  to => 10,  name => 'numero_progressivo',           type => 'an', truncate =>  'no'},
	{from => 11, to => 40,  name => 'indirizzo',                    type => 'an', truncate =>  'no'},
	{from => 41, to => 45,  name => 'cap',                          type => 'an', truncate =>  'no'},
	{from => 46, to => 70,  name => 'comune_e_sigla_provincia',     type => 'an', truncate =>  'no'},
	{from => 71, to => 120, name => 'banca_sportello_beneficiario', type => 'an', truncate =>  'no'},

];

# Record “50” - bonifici
my $L_BON = [
	{from => 1,   to => 1,   name => 'filler1',            type => 'an', truncate =>  'no'},
	{from => 2,   to => 3,   name => 'tipo_record',        type => 'an', truncate =>  'no'},
	{from => 4,   to => 10,  name => 'numero_progressivo', type => 'an', truncate =>  'no'},
	{from => 11,  to => 40,  name => '1_segmento',         type => 'an', truncate =>  'no'},
	{from => 41,  to => 70,  name => '2_segmento',         type => 'an', truncate =>  'no'},
	{from => 71,  to => 100, name => '3_segmento',         type => 'an', truncate =>  'no'},
	{from => 101, to => 120, name => 'filler2',            type => 'an', truncate =>  'no'},
];

# Record “50”
my $L = [
	{from => 1,   to => 1,   name => 'filler1',                    type => 'an', truncate =>  'no'},
	{from => 2,   to => 3,   name => 'tipo_record',                type => 'an', truncate =>  'no'},
	{from => 4,   to => 10,  name => 'numero_progressivo',         type => 'n',  truncate =>  'no'},
	{from => 11,  to => 50,  name => '1_segmento',                 type => 'an', truncate =>  'yes'},
	{from => 51,  to => 90,  name => '2_segmento',                 type => 'an', truncate =>  'yes'},
	{from => 91,  to => 100, name => 'filler2',                    type => 'an', truncate =>  'no'},
	{from => 101, to => 116, name => 'codifica_fiscale_creditore', type => 'an', truncate =>  'no'},
	{from => 117, to => 120, name => 'filler3',                    type => 'an', truncate =>  'no'},
];

# Record “51”
my $LI = [
	{from => 1,  to => 1,   name => 'filler1',                 type => 'an', truncate =>  'no'},
	{from => 2,  to => 3,   name => 'tipo_record',             type => 'an', truncate =>  'no'},
	{from => 4,  to => 10,  name => 'numero_progressivo',      type => 'n',  truncate =>  'no'},
	{from => 11, to => 20,  name => 'numero_ricevuta',         type => 'n',  truncate =>  'no'},
	{from => 21, to => 40,  name => 'denominazione_creditore', type => 'an', truncate =>  'yes'},
	{from => 41, to => 55,  name => 'provincia_bollo',         type => 'an', truncate =>  'no'},
	{from => 56, to => 65,  name => 'numero_autorizzazione',   type => 'an', truncate =>  'no'},
	{from => 66, to => 71,  name => 'data_autorizzazione',     type => 'an', truncate =>  'no'},
	{from => 72, to => 120, name => 'filler2',                 type => 'an', truncate =>  'no'},
];

# Record “59”
my $LIX = [
	{from => 1,  to => 1,   name => 'filler1',            type => 'an', truncate =>  'no'},
	{from => 2,  to => 3,   name => 'tipo_record',        type => 'an', truncate =>  'no'},
	{from => 4,  to => 10,  name => 'numero_progressivo', type => 'an', truncate =>  'no'},
	{from => 11, to => 65,  name => '1_segmento',         type => 'an', truncate =>  'no'},
	{from => 66, to => 120, name => '2_segmento',         type => 'an', truncate =>  'no'},
];

# Record “60”
my $LX = [
	{from => 1,   to => 1,   name => 'filler1',            type => 'an', truncate =>  'no'},
	{from => 2,   to => 3,   name => 'tipo_record',        type => 'an', truncate =>  'no'},
	{from => 4,   to => 10,  name => 'numero_progressivo', type => 'an', truncate =>  'no'},
	{from => 11,  to => 40,  name => '1_segmento',         type => 'an', truncate =>  'no'},
	{from => 41,  to => 70,  name => '2_segmento',         type => 'an', truncate =>  'no'},
	{from => 71,  to => 100, name => '3_segmento',         type => 'an', truncate =>  'no'},
	{from => 101, to => 120, name => 'filler2',            type => 'an', truncate =>  'no'},
];

# Record “70”
my $LXX = [
	{from => 1,   to => 1,   name => 'filler1',                      type => 'an', truncate =>  'no'},
	{from => 2,   to => 3,   name => 'tipo_record',                  type => 'an', truncate =>  'no'},
	{from => 4,   to => 10,  name => 'numero_progressivo',           type => 'n',  truncate =>  'no'},
	{from => 11,  to => 88,  name => 'filler2',                      type => 'an', truncate =>  'no'},
	{from => 89,  to => 100, name => 'indicatori_di_circuito',       type => 'an', truncate =>  'no'},
	{from => 101, to => 103, name => 'indicatore_richiesta_incasso', type => 'n',  truncate =>  'no'},
	{from => 104, to => 120, name => 'chiavi_di_controllo',          type => 'an', truncate =>  'no'},
];

# Record “70” - bonifici
my $LXX_BON = [
	{from => 1,   to => 1,   name => 'filler1',                 type => 'an', truncate =>  'no'},
	{from => 2,   to => 3,   name => 'tipo_record',             type => 'an', truncate =>  'no'},
	{from => 4,   to => 10,  name => 'numero_progressivo',      type => 'an', truncate =>  'no'},
	{from => 11,  to => 25,  name => 'filler2',                 type => 'an', truncate =>  'no'},
	{from => 26,  to => 30,  name => 'campo_non_disponibile',   type => 'an', truncate =>  'no'},
	{from => 31,  to => 31,  name => 'tipo_flusso',             type => 'an', truncate =>  'no'},
	{from => 32,  to => 32,  name => 'qualificatore_flusso',    type => 'an', truncate =>  'no'},
	{from => 33,  to => 37,  name => 'soggetto_veicolatore',    type => 'an', truncate =>  'no'},
	{from => 38,  to => 42,  name => 'codice_mp',               type => 'an', truncate =>  'no'},
	{from => 43,  to => 69,  name => 'filler3',                 type => 'an', truncate =>  'no'},
	{from => 70,  to => 70,  name => 'flag_richiesta',          type => 'an', truncate =>  'no'},
	{from => 71,  to => 100, name => 'codice_univoco',          type => 'an', truncate =>  'no'},
	{from => 101, to => 110, name => 'filler4',                 type => 'an', truncate =>  'no'},
	{from => 111, to => 111, name => 'cin_coordinate_bancaria', type => 'an', truncate =>  'no'},
	{from => 112, to => 112, name => 'filler5',                 type => 'an', truncate =>  'no'},
	{from => 113, to => 120, name => 'chiavi_di_controllo',     type => 'an', truncate =>  'no'},
];


# Record “14” - flusso di ritorno
my $XIV_IN = [
	{from => 1,   to => 1,   name => 'filler1',                 type => 'an', truncate =>  'no'},
	{from => 2,   to => 3,   name => 'tipo_record',             type => 'an', truncate =>  'no'},
	{from => 4,   to => 10,  name => 'numero_progressivo',      type => 'an', truncate =>  'no'},
	{from => 11,  to => 22,  name => 'filler2',                 type => 'an', truncate =>  'no'},
	{from => 23,  to => 28,  name => 'data_pagamento',          type => 'an', truncate =>  'no'},
	{from => 29,  to => 33,  name => 'causale',                 type => 'an', truncate =>  'no'},
	{from => 34,  to => 46,  name => 'importo',                 type => 'an', truncate =>  'no'},
	{from => 47,  to => 47,  name => 'segno',                   type => 'an', truncate =>  'no'},
	{from => 48,  to => 52,  name => 'codice_abi_esattrice',    type => 'an', truncate =>  'no'},
	{from => 53,  to => 57,  name => 'cab_esattrice',           type => 'an', truncate =>  'no'},
	{from => 58,  to => 69,  name => 'filler3',                 type => 'an', truncate =>  'no'},
	{from => 70,  to => 74,  name => 'codice_abi_assuntrice',   type => 'an', truncate =>  'no'},
	{from => 75,  to => 79,  name => 'cab_assuntrice',          type => 'an', truncate =>  'no'},
	{from => 80,  to => 91,  name => 'conto',                   type => 'an', truncate =>  'no'},
	{from => 92,  to => 96,  name => 'codice_azienda',          type => 'an', truncate =>  'no'},
	{from => 97,  to => 97,  name => 'tipo_codice',             type => 'an', truncate =>  'no'},
	{from => 98,  to => 113, name => 'codice_cliente_debitore', type => 'an', truncate =>  'no'},
	{from => 114, to => 119, name => 'filler4',                 type => 'an', truncate =>  'no'},
	{from => 120, to => 120, name => 'codice_divisa',           type => 'an', truncate =>  'no'},
];

# Record “51” - flusso di ritorno
my $LI_IN = [
	{from => 1,  to => 1,   name => 'filler1',                       type => 'an', truncate =>  'no'},
	{from => 2,  to => 3,   name => 'tipo_record',                   type => 'an', truncate =>  'no'},
	{from => 4,  to => 10,  name => 'numero_progressivo',            type => 'an', truncate =>  'no'},
	{from => 11, to => 20,  name => 'numero_disposizione',           type => 'an', truncate =>  'no'},
	{from => 21, to => 74,  name => 'filler2',                       type => 'an', truncate =>  'no'},
	{from => 75, to => 86,  name => 'codice_identificativo_univoco', type => 'an', truncate =>  'no'},
	{from => 87, to => 120, name => 'filler3',                       type => 'an', truncate =>  'no'},
];

our $OUTPUT_RECORD_MAPPING = {
	'IM' => $IM,
	'EF' => $EF,
	'PC' => $PC,
	'10' => $X,
	'14' => $XIV,
	'16' => $XVI,
	'17' => $XVII,
	'20' => $XX,
	'30' => $XXX,
	'40' => $XL,
	'50' => $L,
	'51' => $LI,
	'59' => $LIX,
	'70' => $LXX,
	'IB' => $IB,
};

our $INPUT_RECORD_MAPPING = {
	'IM' => $IM,
	'EF' => $EF,
	'14' => $XIV_IN,
	'20' => $XX,
	'30' => $XXX,
	'40' => $XL,
	'50' => $L,
	'51' => $LI_IN,
	'59' => $LIX,
	'70' => $LXX,
	'IB' => $IB,
};

our $RICEVUTE_BANCARIE = {
	'IB' => $IB,
	'EF' => $EF,
	'14' => $XIV,
	'20' => $XX,
	'30' => $XXX,
	'40' => $XL,
	'50' => $L,
	'51' => $LI,
	'70' => $LXX,
};

our $MAV = {
	'IM' => $IM,
	'EF' => $EF,
	'14' => $XIV_IN,
	'20' => $XX,
	'30' => $XXX,
	'40' => $XL,
	'50' => $L,
	'51' => $LI_IN,
	'59' => $LIX,
	'70' => $LXX,
	'IB' => $IB,
};

our $BONIFICI = {
	'PC' => $PC,        # testa
	'10' => $X,
	'16' => $XVI,
	'17' => $XVII,
	'20' => $XX_BON,
	'30' => $XXX_BON,
	'40' => $XL_BON,
	'50' => $L_BON,
	'60' => $LX,
	'70' => $LXX_BON,
	'EF' => $EF_BON,    # coda
};

our $BONIFICI_ESTERI = {
	'PE' => $PE,           #testa
	                       # ...
	'EF' => $EF_BON_ES,    #coda
};

our $RECORD_MAPPING = {
	IM                    => $IM,
	PC                    => $PC,
	PE                    => $PE,
	EF                    => $EF,
	EF_BON                => $EF_BON,
	EF_BON_ES             => $EF_BON_ES,
	X                     => $X,
	XIV                   => $XIV,
	XVI                   => $XVI,
	XVII                  => $XVII,
	XX                    => $XX,
	XX_BON                => $XX_BON,
	XXX                   => $XXX,
	XXX_BON               => $XXX_BON,
	XL                    => $XL,
	XL_BON                => $XL_BON,
	L_BON                 => $L_BON,
	L                     => $L,
	LI                    => $LI,
	LIX                   => $LIX,
	LX                    => $LX,
	LXX                   => $LXX,
	LXX_BON               => $LXX_BON,
	IB                    => $IB,
	XIV_IN                => $XIV_IN,
	LI_IN                 => $LI_IN,
	OUTPUT_RECORD_MAPPING => $OUTPUT_RECORD_MAPPING,
	INPUT_RECORD_MAPPING  => $INPUT_RECORD_MAPPING,
	MAV                   => $MAV,
	BONIFICI              => $BONIFICI,
	BONIFICI_ESTERI       => $BONIFICI_ESTERI,
	RICEVUTE_BANCARIE     => $RICEVUTE_BANCARIE,
};

1;
