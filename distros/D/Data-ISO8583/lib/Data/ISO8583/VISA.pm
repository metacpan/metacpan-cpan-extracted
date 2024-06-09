##############################################################################
#
#  ISO8583 VISA-specific dictionaries and functions
#  Copyright (c) 2011-2024 Vladi Belperchinov-Shabanski "Cade" 
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/  
#  https://github.com/cade-vs/perl-data-iso8583
#
#  this modules has VISA-specific functionality. it should be used as 
#  companion module to Data::ISO8583
#
#  GPL
#
##############################################################################
package Data::ISO8583::VISA;
use strict;
use Exporter;

our $VERSION = '2.43';

our @ISA    = qw( Exporter );
our @EXPORT = qw(

                $VISA_MESSAGE_FIELDS
                $VISA_MESSAGE_FIELD_60
                $VISA_MESSAGE_FIELD_61
                $VISA_MESSAGE_FIELD_62
                $VISA_MESSAGE_FIELD_63
                
                );

##############################################################################

# [P]os     
# [N]ame    
# [T]ype    => 0 undef, 1 fixed, 2 var
# [L]en     
# [C]onvert => 0 dont, 1 bcd, 2 ebcdic, 9 hex binary data
# chec[K]   => 0 dont, 1 N, 2 A, 3 AN, 4 ANS
# [D]escribe

our $VISA_MESSAGE_FIELDS = {

   2 => { N => 'PAN ',                                        T => 2, L => 11, C => 1, D => '1 B + 19 BCD1' },
   3 => { N => 'Processing Code',                             T => 1, L =>  3, C => 1, D => '6 BCD' },
   4 => { N => 'Amount, Transaction',                         T => 1, L =>  6, C => 1, D => '12 BCD' },
   5 => { N => 'Amount, Settlement',                          T => 1, L =>  6, C => 1, D => '12 BCD' },
   6 => { N => 'Amount, Cardholder Billing',                  T => 1, L =>  6, C => 1, D => '12 BCD' },
   7 => { N => 'Transmission Date and Time',                  T => 1, L =>  5, C => 1, D => '10 BCD' },
   8 => { N => 'Amount, Cardholder Billing Fee',              T => 1, L =>  4, C => 1, D => '8 BCD' },
   9 => { N => 'Conversion Rate, Settlement',                 T => 1, L =>  4, C => 1, D => '8 BCD' },
  10 => { N => 'Conversion Rate, Cardholder Billing',         T => 1, L =>  4, C => 1, D => '8 BCD' },
  11 => { N => 'System Trace Audit Number',                   T => 1, L =>  3, C => 1, D => '6 BCD' },
  12 => { N => 'Time, Local Transaction',                     T => 1, L =>  3, C => 1, D => '6 BCD' },
  13 => { N => 'Date, Local Transaction',                     T => 1, L =>  2, C => 1, D => '4 BCD' },
  14 => { N => 'Date, Expiration',                            T => 1, L =>  2, C => 1, D => '4 BCD' },
  15 => { N => 'Date, Settlement',                            T => 1, L =>  2, C => 1, D => '4 BCD' },
  16 => { N => 'Date, Conversion',                            T => 1, L =>  2, C => 1, D => '4 BCD' },
  17 => { N => 'Date, Capture',                               T => 1, L =>  4, D => '4 N' },
  18 => { N => 'Merchant Type',                               T => 1, L =>  2, C => 1, D => '4 BCD' },
  19 => { N => 'Acquiring Institution Country Code',          T => 1, L =>  2, C => 1, D => '3 BCD1' },
  20 => { N => 'PAN Extended, Country Code',                  T => 1, L =>  2, C => 1, D => '3 BCD1' },
  22 => { N => 'POS Entry Mode Code',                         T => 1, L =>  2, C => 1, D => '4 BCD' },
  23 => { N => 'Card Sequence Number',                        T => 1, L =>  2, C => 1, D => '3 BCD' },
  24 => { N => 'Network International Identifier',            T => 1, L =>  2, C => 1, D => '3 BCD1' },
  25 => { N => 'POS Condition Code',                          T => 1, L =>  1, C => 1, D => '2 BCD' },
  26 => { N => 'POS PIN Capture Code',                        T => 1, L =>  1, C => 1, D => '2 BCD' },
  28 => { N => 'Amount, Transaction Fee',                     T => 1, L =>  9, C => 0, D => '1 AN + 8 N' },
  32 => { N => 'Acquiring Institution Identification Code ',  T => 2, L =>  7, C => 1, D => '1 B + 11 BCD1' },
  33 => { N => 'Forwarding Institution Identification Code ', T => 2, L =>  7, C => 1, D => '1 B + 11 BCD1' },
  34 => { N => 'Acceptance Environment Data ',                T => 2, E =>  2, L => 1537, C => 0, D => '2 bytes + 1535' },
  35 => { N => 'Track 2 Data ',                               T => 2, L => 20, C => 1, D => '1 B + 37 BCD1 and hex D' },
  36 => { N => 'Track 3 Data ',                               T => 2, L => 53, C => 1, D => '1 B + 104 BCD' },
  37 => { N => 'Retrieval Reference Number',                  T => 1, L => 12, C => 2, D => '12 AN2' },
  38 => { N => 'Authorization Identification Response',       T => 1, L =>  6, D => '6 AN' },
  39 => { N => 'Response Code',                               T => 1, L =>  2, D => '2 AN' },
  41 => { N => 'Card Acceptor Terminal Identification',       T => 1, L =>  8, C => 2, D => '8 ANS' },
  42 => { N => 'Card Acceptor Identification Code',           T => 1, L => 15, C => 2, D => '15 ANS' },
  43 => { N => 'Card Acceptor Name/Location',                 T => 1, L => 40, C => 2, D => '40 ANS' },
  44 => { N => 'Additional Response Data ',                   T => 2, L => 26, C => 2, D => '1 B + 25 ANS3' },
  45 => { N => 'Track 1 Data ',                               T => 2, L => 77, C => 2, D => '1 B + 76 ANS' },
  46 => { N => 'Amounts, Fees',                               T => 2, L => 256, '1 B + 255 ANS' },
  47 => { N => 'Additional Data—National ',                   T => 2, L => 256, D => '1 B + 255 ANS' },
  48 => { N => 'Additional Data—Private ',                    T => 2, L => 256, D => '1 B + 255 ANS4' },
  49 => { N => 'Currency Code, Transaction',                  T => 1, L => 2, C => 1, D => '3 BCD1' },
  50 => { N => 'Currency Code, Settlement',                   T => 1, L => 2, C => 1, D => '3 BCD1' },
  51 => { N => 'Currency Code, Cardholder Billing',           T => 1, L => 2, C => 1, D => '3 BCD1' },
  52 => { N => 'Personal Identification Number (PIN) Data',   T => 1, L => 8, D => '64-bit string' },
  53 => { N => 'Security-Related Control Information',        T => 1, L => 8, C => 1, D => '16 BCD' },
  54 => { N => 'Additional Amounts ',                         T => 2, L => 121, C => 2, D => '1 B + 120 ANS' },
  55 => { N => 'Integrated Circuit Card (ICC) Related Data',  T => 2, L => 256, C => 2, D => '1 B + 256 ANS' },
  56 => { N => 'Payment Account Reference Data ',             T => 2, L => 256, C => 2, D => '1 B + 255 ANS' },
  57 => { N => 'Reserved National ',                          T => 2, L => 256, C => 2, D => '1 B + 255 ANS' },
  58 => { N => 'Reserved National ',                          T => 2, L => 256, C => 2, D => '1 B + 255 ANS' },
  59 => { N => 'National POS Geographic Data',                T => 2, L =>  15, C => 2, D => '1 B + 14 ANS' },
  60 => { N => 'Additional POS Information ',                 T => 2, L =>   7, C => 1, D => '1 B + 12N, 4 bit BCD' },
  61 => { N => 'Other Amounts ',                              T => 2, L =>  19, C => 1, D => '1 B + 12, 24, 36 BCD' },
  62 => { N => 'Custom Payment Service Fields Bitmap',        T => 2, L => 256, C => 9, D => '1 B + 255 byte' },
  63 => { N => 'V.I.P. Private-Use Fields ',                  T => 2, L => 256, C => 9, D => '1 B + 255 bytes' },
  64 => { N => 'Message Authentication Code',                 T => 1, L =>   8, C => 9, D => '64-bit string' },
  66 => { N => 'Settlement Code',                             T => 1, L =>   1, C => 1, D => '1 BCD1' },
  67 => { N => 'Extended Payment Code',                       T => 1, L =>   1, C => 1, D => '2 BCD' },
  68 => { N => 'Receiving Institution Country Code',          T => 1, L =>   2, C => 1, D => '3 BCD1' },
  69 => { N => 'Settlement Institution Country Code',         T => 1, L =>   2, C => 1, D => '3 BCD1' },
  70 => { N => 'Network Management Information Code',         T => 1, L =>   2, C => 1, D => '3 BCD1' },
  71 => { N => 'Message Number',                              T => 1, L =>   2, C => 1, D => '4 BCD' },
  72 => { N => 'Message Number Last',                         T => 1, L =>   2, C => 1, D => '4 BCD' },
  73 => { N => 'Date, Action',                                T => 1, L =>   3, C => 1, D => '6 BCD' },
  74 => { N => 'Credits, Number',                             T => 1, L =>   5, C => 1, D => '10 BCD' },
  75 => { N => 'Credits, Reversal Number',                    T => 1, L =>   5, C => 1, D => '10 BCD' },
  76 => { N => 'Debits, Number',                              T => 1, L =>   5, C => 1, D => '10 BCD' },
  77 => { N => 'Debits, Reversal Number',                     T => 1, L =>   5, C => 1, D => '10 BCD' },
  78 => { N => 'Transfer, Number',                            T => 1, L =>   5, C => 1, D => '10 BCD' },
  79 => { N => 'Transfer, Reversal Number',                   T => 1, L =>   5, C => 1, D => '10 BCD' },
  80 => { N => 'Inquiries, Number',                           T => 1, L =>   5, C => 1, D => '10 BCD' },
  81 => { N => 'Authorizations, Number',                      T => 1, L =>   5, C => 1, D => '10 BCD' },
  82 => { N => 'Credits, Processing Fee Amount',              T => 1, L =>   6, C => 1, D => '12 BCD' },
  83 => { N => 'Credits, Transaction Fee Amount',             T => 1, L =>   6, C => 1, D => '12 BCD' },
  84 => { N => 'Debits, Processing Fee Amount',               T => 1, L =>   6, C => 1, D => '12 BCD' },
  85 => { N => 'Debits, Transaction Fee Amount',              T => 1, L =>   6, C => 1, D => '12 BCD' },
  86 => { N => 'Credits, Amount',                             T => 1, L =>   8, C => 1, D => '16 BCD' },
  87 => { N => 'Credits, Reversal Amount',                    T => 1, L =>   8, C => 1, D => '16 BCD' },
  88 => { N => 'Debits, Amount',                              T => 1, L =>   8, C => 1, D => '16 BCD' },
  89 => { N => 'Debits, Reversal Amount',                     T => 1, L =>   8, C => 1, D => '16 BCD' },
  90 => { N => 'Original Data Elements',                      T => 1, L =>  21, C => 1, D => '42 BCD' },
  91 => { N => 'File Update Code',                            T => 1, L =>   1, D => '1 AN' },
  92 => { N => 'File Security Code',                          T => 1, L =>   2, D => '2 AN' },
  94 => { N => 'Service Indicator',                           T => 1, L =>   7, D => '7 AN' },
  95 => { N => 'Replacement Amounts',                         T => 1, L =>  42, D => '42 AN' },
  96 => { N => 'Reserved for future use',                     T => 0 },
  97 => { N => 'Amount, Net Settlement',                      T => 1, L =>  17, D => '17 AN' },
  98 => { N => 'Payee',                                       T => 1, L =>  25, D => '25 ANS' },
  99 => { N => 'Settlement Institution Identification Code ', T => 2, L =>   7, C => 1, D => '1 B + 11 BCD1' },
 100 => { N => 'Receiving Institution Identification Code ',  T => 2, L =>   7, C => 1, D => '1 B + 11 BCD1' },
 101 => { N => 'File Name ',                                  T => 2, L =>  18, D => '1 B + 17 ANS' },
 102 => { N => 'Account Identification 1 ',                   T => 2, L =>  29, D => '1 B + 28 ANS' },
 103 => { N => 'Account Identification 2 ',                   T => 2, L =>  29, D => '1 B + 28 ANS' },
 104 => { N => 'Transaction Description ',                    T => 2, L => 256, D => '1 B + 255 ANS' },
 105 => { N => 'Double-Length DES Key (Triple DES)',          T => 1, L => 128, D => '128–bit string' },
 106 => { N => 'Reserved ISO ',                               T => 2, L => 256, D => '1 B + 255 ANS' },
 107 => { N => 'Reserved ISO ',                               T => 2, L => 256, D => '1 B + 255 ANS' },
 108 => { N => 'Reserved ISO ',                               T => 2, L => 256, D => '1 B + 255 ANS' },
 109 => { N => 'Reserved ISO ',                               T => 2, L => 256, D => '1 B + 255 ANS' },
 110 => { N => 'Encryption Data (TLV Format) ',               T => 2, E => 2, L => 1537, D => '2 B + 1535 B' },
 111 => { N => 'Additional Transaction Data (TLV Format) ',   T => 2, E => 2, L => 1537, D => '2 B + 1535' },
 112 => { N => 'Reserved National ',                          T => 2, L => 256, D => '1 B + 255 ANS' },
 113 => { N => 'Reserved National ',                          T => 2, L => 256, D => '1 B + 255 ANS' },
 114 => { N => 'Domestic and Localized Data (TLV Format) ',   T => 2, E => 2, L => 1537, D => '2 B + 1535 B' },
 115 => { N => 'Additional Trace Data ',                      T => 2, L => 25, D => '1 B + 24 ANS' },
 116 => { N => 'Card Issuer Reference Data ',                 T => 2, L => 256, D => '1 B + 255 ANS' },
 117 => { N => 'National Use ',                               T => 2, L => 256, D => '1 B + 3 ANS + 252 ANS' },
 118 => { N => 'Intra-Country Data ',                         T => 2, L => 256, D => '1 B + 3 ANS + 252 ANS' },
 119 => { N => 'Settlement Service Data (International) ',    T => 2, L => 256, D => '1 B + 255 ANS' },
 120 => { N => 'Auxiliary Transaction Data (TLV Format) ',    T => 2, E => 2, L => 1537, D => '2 B + 1535 B' },
 121 => { N => 'Issuing Institution Identification Code ',    T => 2, L => 12, D => '1 B + 3 to 11 AN' },
 123 => { N => 'Verification Data',                           T => 2, L => 256, D => '1 B + 255 B and ANS' },
 125 => { N => 'Supporting Information ',                     T => 2, L => 256, D => '1 B + 255 ANS' },
 126 => { N => 'Visa Private-Use Fields ',                    T => 2, L => 256, D => '1 B + 255 ANS' },
 127 => { N => 'File Maintenance ',                           T => 2, L => 256, D => '1 B + 255 bytes' },
 128 => { N => 'Message Authentication Code',                 T => 1, L =>   8, C => 2, D => '64-bit string' },
};

# [P]os     
# [N]ame    
# [T]ype    => 0 undef, 1 fixed, 2 var
# [L]en     
# [C]onvert => 0 dont, 1 bcd, 2 ebcdic, 9 hex binary data
# chec[K]   => 0 dont, 1 N, 2 A, 3 AN, 4 ANS
# [D]escribe

our $VISA_MESSAGE_FIELD_60 = {

  # NOTE: no BITMAP used, all present
  1 => { N => 'Terminal Type',                                    T => 1, L =>  1, C => 0, K => 1, D => '1 N' },
  2 => { N => 'Terminal Entry Capability',                        T => 1, L =>  1, C => 0, K => 1, D => '1 N' },
  3 => { N => 'Chip Condition Code',                              T => 1, L =>  1, C => 1, K => 0, D => '1 N, 4 bit BCD' },
  4 => { N => 'Existing Debt Indicator',                          T => 1, L =>  1, C => 0, K => 1, D => '1 N' },
  5 => { N => 'Merchant Group Indicator',                         T => 1, L =>  3, C => 0, K => 1, D => '2 N' },
  6 => { N => 'Chip Transaction Indicator',                       T => 1, L =>  1, C => 0, K => 1, D => '1 N' },
  7 => { N => 'Chip Card Authentication Reliability Ind.',        T => 1, L =>  1, C => 0, K => 1, D => '1 N' },
  8 => { N => 'Mail/Phone/Electronic Commerce and Payment Ind.',  T => 1, L =>  2, C => 0, K => 1, D => '2 N' },
  9 => { N => 'Cardholder ID Method Indicator',                   T => 1, L =>  1, C => 0, K => 1, D => '1 N' },
 10 => { N => 'Partial Authorization Indicator',                  T => 1, L =>  1, C => 0, K => 1, D => '1 N' },

};

# [P]os     
# [N]ame    
# [T]ype    => 0 undef, 1 fixed, 2 var
# [L]en     
# [C]onvert => 0 dont, 1 bcd, 2 ebcdic, 9 hex binary data
# chec[K]   => 0 dont, 1 N, 2 A, 3 AN, 4 ANS
# [D]escribe

our $VISA_MESSAGE_FIELD_61 = {

  # NOTE: no BITMAP used, all present
  1 => { N => 'Other Amount, Transaction',          T => 1, L =>  6, C => 1, K => 1, D => '12 BCD' },
  2 => { N => 'Other Amount, Cardholder Billing',   T => 1, L =>  6, C => 1, K => 1, D => '12 BCD' },
  3 => { N => 'Other Amount, Replacement Billing',  T => 1, L =>  6, C => 1, K => 1, D => '12 BCD' },

};

# [P]os     
# [N]ame    
# [T]ype    => 0 undef, 1 fixed, 2 var
# [L]en     
# [C]onvert => 0 dont, 1 bcd, 2 ebcdic, 9 hex binary data
# chec[K]   => 0 dont, 1 N, 2 A, 3 AN, 4 ANS
# [D]escribe

our $VISA_MESSAGE_FIELD_62 = {

  1 => { N => 'Authorization Characteristics Indicator',      T => 1, L =>  1, C => 0, K => 3, D => '1 AN'            },
  2 => { N => 'Transaction Identifier',                       T => 1, L =>  8, C => 1, K => 1, D => '15 BCD'          },
  3 => { N => 'Validation Code',                              T => 1, L =>  4, C => 0, K => 3, D => '4 AN'            },
  4 => { N => 'Market-Specific Data Identifier',              T => 1, L =>  1, C => 0, K => 3, D => '1 AN'            },
  5 => { N => 'Duration',                                     T => 1, L =>  1, C => 1, K => 1, D => '2 BCD'           },
  6 => { N => 'Reserved',                                     T => 1, L =>  1, C => 0, K => 3, D => '1 AN'            },
  7 => { N => 'Purchase Identifier',                          T => 1, L => 26, C => 0, K => 3, D => '26 AN'           },
  8 => { N => 'Car Rental Check-Out, Lodging Check-In Date',  T => 1, L =>  3, C => 1, K => 1, D => '6 BCD'           },
  9 => { N => 'No Show Indicator',                            T => 1, L =>  1, C => 0, K => 3, D => '1 AN'            },
 10 => { N => 'Extra Charges',                                T => 1, L =>  3, C => 1, K => 1, D => '6 BCD'           },
 11 => { N => 'Multiple Clearing Sequence Number',            T => 1, L =>  1, C => 1, K => 1, D => '2 BCD'           },
 12 => { N => 'Multiple Clearing Sequence Count',             T => 1, L =>  1, C => 1, K => 1, D => '2 BCD'           },
 13 => { N => 'Restricted Ticket Indicator',                  T => 1, L =>  1, C => 0, K => 3, D => '1 AN'            },
 14 => { N => 'Total Amount Authorized',                      T => 1, L =>  6, C => 1, K => 1, D => '12 BCD'          },
 15 => { N => 'Requested Payment Service',                    T => 1, L =>  1, C => 0, K => 3, D => '1 AN'            },
 16 => { N => 'Reserved',                                     T => 1, L =>  2, C => 0, K => 3, D => '2 AN'            }, 
 17 => { N => 'Gateway Transaction Identifier',               T => 1, L => 15, C => 2, K => 0, D => '15 EBCDIC'       }, 
 18 => { N => 'Excluded Transaction Identifier Reason Code',  T => 1, L =>  1, C => 0, K => 3, D => '1 AN'            }, 
 19 => { N => 'Electronic Commerce Goods Indicator (U.S.)',   T => 1, L =>  2, C => 0, K => 3, D => '2 AN'            }, 
 20 => { N => 'Merchant Verification Value (MVV)',            T => 1, L =>  5, C => 0, K => 0, D => '10 N, 4-bit BCD' },
 21 => { N => 'Online Risk Assessment Risk Score and Reason', T => 1, L =>  4, C => 2, K => 3, D => '4 AN, EBCDIC'    },
 22 => { N => 'Online Risk Assessment Condition Codes',       T => 1, L =>  6, C => 2, K => 3, D => '6 AN, EBCDIC'    },
 23 => { N => 'Product ID',                                   T => 1, L =>  2, C => 2, K => 3, D => '2 AN, EBCDIC'    },
 24 => { N => 'Program Identifier',                           T => 1, L =>  6, C => 2, K => 3, D => '6 AN, EBCDIC'    },
 25 => { N => 'Spend Qualified Indicator',                    T => 1, L =>  1, C => 2, K => 3, D => '1 AN, EBCDIC'    },

};

# [P]os     
# [N]ame    
# [T]ype    => 0 undef, 1 fixed, 2 var
# [L]en     
# [C]onvert => 0 dont, 1 bcd, 2 ebcdic, 9 hex binary data
# chec[K]   => 0 dont, 1 N, 2 A, 3 AN, 4 ANS
# [D]escribe

our $VISA_MESSAGE_FIELD_63 = {

  1 => { N => 'Network Identification Code',              T => 1, L =>  2, C => 1, K => 1, D => 'F 2 4 BCD'     },
  2 => { N => 'Time (Preauth Time Limit)',                T => 1, L =>  2, C => 1, K => 1, D => 'F 2 4 BCD'     },
  3 => { N => 'Message Reason Code',                      T => 1, L =>  2, C => 1, K => 1, D => 'F 2 4 BCD'     },
  4 => { N => 'STIP/Switch Reason Code',                  T => 1, L =>  2, C => 1, K => 1, D => 'F 2 4 BCD'     },
  6 => { N => 'Chargeback Reduction/BASE II Flags',       T => 1, L =>  7, C => 2, K => 4, D => 'F 7 7 ANS'     },
  7 => { N => 'Network Participation Flags (U.S. Only)',  T => 1, L =>  8, C => 9, K => 0, D => 'F 8 64-bit string (n/a)'    },
  8 => { N => 'Visa Acquirer Business ID (U.S. Only)',    T => 1, L =>  4, C => 1, K => 1, D => 'F 4 8 BCD'     },
  9 => { N => 'Fraud Data',                               T => 1, L => 14, C => 2, K => 4, D => 'F 14 14 ANS'   },
 10 => { N => 'Gateway Merchant Data (U.S. Only)',        T => 1, L => 13, C => 2, K => 4, D => 'F 13 13 ANS'   },
 11 => { N => 'Reimbursement Attribute',                  T => 1, L =>  1, C => 2, K => 4, D => 'F 1 1 ANS'     },
 12 => { N => 'Sharing Group Code (U.S. Only)',           T => 1, L => 30, C => 2, K => 4, D => 'F 30 30 ANS'   },
 13 => { N => 'Decimal Positions Indicator',              T => 1, L =>  3, C => 1, K => 1, D => 'F 3 64 BCD'    },
 14 => { N => 'Issuer Currency Conversion Data',          T => 1, L => 36, C => 2, K => 4, D => 'F 36 36 ANS'   },
 15 => { N => 'Reserved',                                 T => 1, L =>  8, C => 2, K => 4, D => 'F 8 8 ANS'     },
 16 => { N => 'Reserved for future use',                  T => 0,                                               },
 17 => { N => 'Reserved for future use',                  T => 0,                                               },
 18 => { N => 'Merchant Volume Indicator (U.S. Only)',    T => 1, L =>  2, C => 1, K => 1, D => 'F 2 4 BCD'     },
 19 => { N => 'Fee Program Indicator',                    T => 1, L =>  3, C => 0, K => 3, D => 'F 3 3 AN'      },
 21 => { N => 'Charge Indicator',                         T => 1, L =>  1, C => 2, K => 4, D => 'F 1 1 ANS'     },

};

=pod


=head1 NAME

  ISO8583 VISA-specific dictionaries and functions

=head1 SYNOPSIS

  use Data::ISO8583;
  use Data::ISO8583::VISA;
  
  my $msg_hash_ref = parse_iso8583_fields( $byte_data, $VISA_MESSAGE_FIELDS );
  
  my ( $fmap_arr_ref, $skip ) = parse_iso8583_bitmap( $byte_data, $len, $one );

  # for more details, see documentation for Data::ISO8583
  
=head1 DESCRIPTION

This module is part of Data::ISO8583 module. Please, see Data::ISO8583
documentation.

This module contains message and fields dictionaries for VISA specifications
as of October 2023.

=head1 GITHUB REPOSITORY

  https://github.com/cade-vs/perl-data-iso8583

  git@github.com:cade-vs/perl-data-iso8583.git
  
  git clone git@github.com:cade-vs/perl-data-iso8583.git
  
  or
  
  git clone https://github.com/cade-vs/perl-data-iso8583.git
  
=head1 AUTHOR

  Copyright (c) 2011-2024 Vladi Belperchinov-Shabanski "Cade"
        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
  http://cade.noxrun.com/  

=cut

1;
