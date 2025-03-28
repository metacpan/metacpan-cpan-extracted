# NAME

CBI::Wrapper - Handle the Italian CBI fixed length file format.

# VERSION

version 0.02

# SYNOPSIS

Allow the handling of the Italian CBI fixed length
file format.
Core based on [https://github.com/eLBati/CBI](https://github.com/eLBati/CBI).
This code is designed mainly to help writing "Ricevute bancarie (Ri.ba)"
data to files.

A typical usage is:

        use CBI::Wrapper;

        my $header = { ... };
        my $disposals = [{ ... }];

        my $cbi = new CBI::Wrapper({header => $header, disposals => $disposals});
        $cbi->create_flow({flow_type => 'RICEVUTE_BANCARIE'});
        $cbi->print('./outfile.cbi');

# DESCRIPTION

`CBI::Wrapper` is a Perl module that allow the handling of the Italian CBI
fixed length file format, mainly to write 
"Ricevute bancarie (Ri.ba)" data to files.

Features include:

- Creation of a flow from header and disposals data.
- Write the desired data on cbi file.
- Load a cbi file.

**Note:** For now only the Ri.ba format is supported.

# LINKS

- [Original Python code](https://github.com/eLBati/CBI)
- [Interbank Corporate Banking](https://www.cbi-org.eu/)

# CONSTRUCTOR AND STARTUP

## new()

Creates and returns a new CBI::Wrapper object.
If the constructor is called without params, the content of header
and disposals won't be defined and you won't be able to create a flow.
You can:

- Pass params to the constructor:
	my $cbi = new CBI::Wrapper ({header => $header, disposals => $disposals});
- Pass header and disposals as params to ["create\_RIBA()"](#create_riba)
- Use the setters ["set\_header({...})"](#set_header) and ["set\_disposals(\[{...}\])"](#set_disposals)

# SETTERS AND GETTERS

## set\_header($header)

Load the header passed as param.
This param is an hashref like this:



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

## get\_header()

Return the current header hashref.

## set\_disposals($disposals)

Load the disposals passed as param.
This param is an arrayref containing the disposals
to insert in the flow.
This hashref is like this:



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

## get\_disposals()

Return the current disposals arrayref.

## set\_flow\_CBI($CBI\_flow)

Set the current CBI::Wrapper::Flow object.

## get\_flow\_CBI()

Get the current CBI::Wrapper::Flow object.

## append\_disposal($disposal)

Append the [disposal hashref](#disposal_hashref) passed as param to the current
disposals.

# FLOW CREATION

## create\_flow()

Create a new flow from the current header and disposals.
If the current header or disposals are undefined, return 0.
You can set a new current header and disposals calling this
method with params like this:

        $cbi->create_flow({header => $header, 
                           disposals => $disposals, 
                           flow_type => $flow_type
        });

# PRINTING AND LOADING FILES

## print($filename)

Prints the current CBI::Wrapper::Flow object to a file
with the filename passed as param.
The current CBI::Wrapper::Flow object is defined when

- ["create\_flow()"](#create_flow) is called;
- a CBI::Wrapper::Flow is passed with ["set\_flow\_CBI($CBI\_flow)"](#set_flow_cbi-cbi_flow);
- a file is [loaded](#load-filename).

## load($filename)

Load a file with the filename passed as param.
This will set a new current CBI::Wrapper::Flow object
with the file content.
This will **NOT** set the current header and disposals.

# OTHER CBI FLOWS

You can configure other flows (es. MAV) editing CBI::Wrapper/RecordMapping.pm
In that file every disposal config is like this:

        my $IB = [
                {from => 1, to => 1, name => 'filler1', type => 'an', truncate =>  'no'},
        ];
        

where

- from is the starting column
- to is the ending column
- type is the field data type (n = numeric, an = string)
- truncate denotes if the string content will be truncated automatically (if length > field length)
or if an error will be thrown.

# ONLINE RESOURCES

- Official documentation [https://www.cbi-org.eu/My-Menu/Servizio-CBI-Documentazione/Servizio-CBI-Documentazione-Standard](https://www.cbi-org.eu/My-Menu/Servizio-CBI-Documentazione/Servizio-CBI-Documentazione-Standard)
(Registration required)

# ACKNOWLEDGEMENTS

Lorenzo Battistini - Author of the Python module from which this code is derived.

# AUTHOR

Samuele Bonino &lt;samuele.bonino at resbinaria.com>

# COPYRIGHT AND LICENSE

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
