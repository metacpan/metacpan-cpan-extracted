package Business::EDI::Composite;

use base 'Business::EDI';

use strict; use warnings;
use Carp;

my $VERSION = 0.03;
my $debug;

my $guts = {

# These are from the EDI SYNTAX specs
'S001' => { label => 'SYNTAX IDENTIFIER', desc => 'SYNTAX IDENTIFIER', parts => {
    '0001' => { pos => '010', def =>      'a4' },
    '0002' => { pos => '020', def =>     'an1' },
    '0080' => { pos => '030', def =>   'an..6' },
    '0133' => { pos => '040', def =>   'an..3' },
    '0076' => { pos => '050', def =>     'an2' },
}},
'S002' => { label => 'INTERCHANGE SENDER', desc => 'INTERCHANGE SENDER', parts => {
    '0004' => { pos => '010', def =>  'an..35' },
    '0007' => { pos => '020', def =>   'an..4' },
    '0008' => { pos => '030', def =>  'an..35' },
    '0042' => { pos => '040', def =>  'an..35' },
}},
'S003' => { label => 'INTERCHANGE RECIPIENT', desc => 'INTERCHANGE RECIPIENT', parts => {
    '0010' => { pos => '010', def =>  'an..35' },
    '0007' => { pos => '020', def =>   'an..4' },
    '0014' => { pos => '030', def =>  'an..35' },
    '0046' => { pos => '040', def =>  'an..35' },
}},
'S004' => { label => 'DATE AND TIME OF PREPARATION', desc => 'DATE AND TIME OF PREPARATION', parts => {
    '0017' => { pos => '010', def =>      'n8' },
    '0019' => { pos => '020', def =>      'n4' },
}},
'S005' => { label => 'RECIPIENT REFERENCE/PASSWORD DETAILS', desc => 'RECIPIENT REFERENCE/PASSWORD DETAILS', parts => {
    '0022' => { pos => '010', def =>  'an..14' },
    '0025' => { pos => '020', def =>     'an2' },
}},
'S006' => { label => 'APPLICATION SENDER IDENTIFICATION', desc => 'APPLICATION SENDER IDENTIFICATION', parts => {
    '0040' => { pos => '010', def =>  'an..35' },
    '0007' => { pos => '020', def =>   'an..4' },
}},
'S007' => { label => 'APPLICATION RECIPIENT IDENTIFICATION', desc => 'APPLICATION RECIPIENT IDENTIFICATION', parts => {
    '0044' => { pos => '010', def =>  'an..35' },
    '0007' => { pos => '020', def =>   'an..4' },
}},
'S008' => { label => 'MESSAGE VERSION', desc => 'MESSAGE VERSION', parts => {
    '0052' => { pos => '010', def =>   'an..3' },
    '0054' => { pos => '020', def =>   'an..3' },
    '0057' => { pos => '030', def =>   'an..6' },
}},
'S009' => { label => 'MESSAGE IDENTIFIER', desc => 'MESSAGE IDENTIFIER', parts => {
    '0065' => { pos => '010', def =>   'an..6' },
    '0052' => { pos => '020', def =>   'an..3' },
    '0054' => { pos => '030', def =>   'an..3' },
    '0051' => { pos => '040', def =>   'an..3' },
    '0057' => { pos => '050', def =>   'an..6' },
    '0110' => { pos => '060', def =>   'an..6' },
    '0113' => { pos => '070', def =>   'an..6' },
}},
'S010' => { label => 'STATUS OF THE TRANSFER', desc => 'STATUS OF THE TRANSFER', parts => {
    '0070' => { pos => '010', def =>    'n..2' },
    '0073' => { pos => '020', def =>      'a1' },
}},
'S011' => { label => 'DATA ELEMENT IDENTIFICATION', desc => 'DATA ELEMENT IDENTIFICATION', parts => {
    '0098' => { pos => '010', def =>    'n..3' },
    '0104' => { pos => '020', def =>    'n..3' },
    '0136' => { pos => '030', def =>    'n..6' },
}},
'S016' => { label => 'MESSAGE SUBSET IDENTIFICATION', desc => 'MESSAGE SUBSET IDENTIFICATION', parts => {
    '0115' => { pos => '010', def =>  'an..14' },
    '0116' => { pos => '020', def =>   'an..3' },
    '0118' => { pos => '030', def =>   'an..3' },
    '0051' => { pos => '040', def =>   'an..3' },
}},
'S017' => { label => 'MESSAGE IMPLEMENTATION GUIDELINE IDENTIFICATION', desc => 'MESSAGE IMPLEMENTATION GUIDELINE IDENTIFICATION', parts => {
    '0121' => { pos => '010', def =>  'an..14' },
    '0122' => { pos => '020', def =>   'an..3' },
    '0124' => { pos => '030', def =>   'an..3' },
    '0051' => { pos => '040', def =>   'an..3' },
}},
'S018' => { label => 'SCENARIO IDENTIFICATION', desc => 'SCENARIO IDENTIFICATION', parts => {
    '0127' => { pos => '010', def =>  'an..14' },
    '0128' => { pos => '020', def =>   'an..3' },
    '0130' => { pos => '030', def =>   'an..3' },
    '0051' => { pos => '040', def =>   'an..3' },
}},
'S020' => { label => 'REFERENCE IDENTIFICATION', desc => 'REFERENCE IDENTIFICATION', parts => {
    '0813' => { pos => '010', def =>   'an..3' },
    '0802' => { pos => '020', def =>  'an..35' },
}},
'S021' => { label => 'OBJECT TYPE IDENTIFICATION', desc => 'OBJECT TYPE IDENTIFICATION', parts => {
    '0805' => { pos => '010', def =>   'an..3' },
    '0809' => { pos => '020', def => 'an..256' },
    '0808' => { pos => '030', def => 'an..256' },
    '0051' => { pos => '040', def =>   'an..3' },
}},
'S022' => { label => 'STATUS OF THE OBJECT', desc => 'STATUS OF THE OBJECT', parts => {
    '0810' => { pos => '010', def =>   'n..18' },
    '0814' => { pos => '020', def =>    'n..3' },
    '0070' => { pos => '030', def =>    'n..2' },
    '0073' => { pos => '040', def =>      'a1' },
}},
'S300' => { label => 'DATE AND/OR TIME OF INITIATION', desc => 'DATE AND/OR TIME OF INITIATION', parts => {
    '0338' => { pos => '010', def =>    'n..8' },
    '0314' => { pos => '020', def =>  'an..15' },
    '0336' => { pos => '030', def =>      'n4' },
}},
'S301' => { label => 'STATUS OF TRANSFER - INTERACTIVE', desc => 'STATUS OF TRANSFER - INTERACTIVE', parts => {
    '0320' => { pos => '010', def =>    'n..6' },
    '0323' => { pos => '020', def =>      'a1' },
    '0325' => { pos => '030', def =>      'a1' },
}},
'S302' => { label => 'DIALOGUE REFERENCE', desc => 'DIALOGUE REFERENCE', parts => {
    '0300' => { pos => '010', def =>  'an..35' },
    '0303' => { pos => '020', def =>  'an..35' },
    '0051' => { pos => '030', def =>   'an..3' },
    '0304' => { pos => '040', def =>  'an..35' },
}},
'S303' => { label => 'TRANSACTION REFERENCE', desc => 'TRANSACTION REFERENCE', parts => {
    '0306' => { pos => '010', def =>  'an..35' },
    '0303' => { pos => '020', def =>  'an..35' },
    '0051' => { pos => '030', def =>   'an..3' },
}},
'S305' => { label => 'DIALOGUE IDENTIFICATION', desc => 'DIALOGUE IDENTIFICATION', parts => {
    '0311' => { pos => '010', def =>  'an..14' },
    '0342' => { pos => '020', def =>   'an..3' },
    '0344' => { pos => '030', def =>   'an..3' },
    '0051' => { pos => '040', def =>   'an..3' },
}},
'S306' => { label => 'INTERACTIVE MESSAGE IDENTIFIER', desc => 'INTERACTIVE MESSAGE IDENTIFIER', parts => {
    '0065' => { pos => '010', def =>   'an..6' },
    '0052' => { pos => '020', def =>   'an..3' },
    '0054' => { pos => '030', def =>   'an..3' },
    '0113' => { pos => '040', def =>   'an..6' },
    '0051' => { pos => '050', def =>   'an..3' },
    '0057' => { pos => '060', def =>   'an..6' },
}},
'S307' => { label => 'STATUS INFORMATION', desc => 'STATUS INFORMATION', parts => {
    '0333' => { pos => '010', def =>   'an..3' },
    '0332' => { pos => '020', def =>  'an..70' },
    '0335' => { pos => '030', def =>   'an..3' },
}},
'S500' => { label => 'SECURITY IDENTIFICATION DETAILS', desc => 'SECURITY IDENTIFICATION DETAILS', parts => {
    '0577' => { pos => '010', def =>   'an..3' },
    '0538' => { pos => '020', def =>  'an..35' },
    '0511' => { pos => '030', def => 'an..1024' },
    '0513' => { pos => '040', def =>   'an..3' },
    '0515' => { pos => '050', def =>   'an..3' },
    '0586' => { pos => '060', def =>  'an..35' },
    '0586' => { pos => '070', def =>  'an..35' },
    '0586' => { pos => '080', def =>  'an..35' },
}},
'S501' => { label => 'SECURITY DATE AND TIME', desc => 'SECURITY DATE AND TIME', parts => {
    '0517' => { pos => '010', def =>   'an..3' },
    '0338' => { pos => '020', def =>    'n..8' },
    '0314' => { pos => '030', def =>  'an..15' },
    '0336' => { pos => '040', def =>      'n4' },
}},
'S502' => { label => 'SECURITY ALGORITHM', desc => 'SECURITY ALGORITHM', parts => {
    '0523' => { pos => '010', def =>   'an..3' },
    '0525' => { pos => '020', def =>   'an..3' },
    '0533' => { pos => '030', def =>   'an..3' },
    '0527' => { pos => '040', def =>   'an..3' },
    '0529' => { pos => '050', def =>   'an..3' },
    '0591' => { pos => '060', def =>   'an..3' },
    '0601' => { pos => '070', def =>   'an..3' },
}},
'S503' => { label => 'ALGORITHM PARAMETER', desc => 'ALGORITHM PARAMETER', parts => {
    '0531' => { pos => '010', def =>   'an..3' },
    '0554' => { pos => '020', def => 'an..512' },
}},
'S504' => { label => 'LIST PARAMETER', desc => 'LIST PARAMETER', parts => {
    '0575' => { pos => '010', def =>   'an..3' },
    '0558' => { pos => '020', def =>  'an..70' },
}},
'S505' => { label => 'SERVICE CHARACTER FOR SIGNATURE', desc => 'SERVICE CHARACTER FOR SIGNATURE', parts => {
    '0551' => { pos => '010', def =>   'an..3' },
    '0548' => { pos => '020', def =>   'an..4' },
}},
'S508' => { label => 'VALIDATION RESULT', desc => 'VALIDATION RESULT', parts => {
    '0563' => { pos => '010', def =>   'an..3' },
    '0560' => { pos => '020', def => 'an..1024' },
}},


# The rest are from regular EDI specs

'C001' => { label => 'TRANSPORT MEANS', desc => 'Code and/or name identifying the type of means of transport.', parts =>{
    8179 => { pos => '010', def => 'an..8' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    8178 => { pos => '040', def => 'an..17', },
}},
'C002' => { label => 'DOCUMENT/MESSAGE NAME', desc => 'Identification of a type of document/message by code or name. Code preferred.', parts =>{
    1001 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    1000 => { pos => '040', def => 'an..35', },
}},
'C004' => { label => 'EVENT CATEGORY', desc => 'To specify the event category.', parts =>{
    9637 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    9636 => { pos => '040', def => 'an..70', },
}},
'C008' => { label => 'MONETARY AMOUNT FUNCTION DETAIL', desc => 'To provide the detail of a monetary amount function.', parts =>{
    5105 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    5104 => { pos => '040', def => 'an..70', },
}},
'C009' => { label => 'INFORMATION CATEGORY', desc => 'To specify the category of information.', parts =>{
    9615 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    9614 => { pos => '040', def => 'an..70', },
}},
'C010' => { label => 'INFORMATION TYPE', desc => 'To specify the type of information.', parts =>{
    4473 => { pos => '010', def => 'an..4' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    4472 => { pos => '040', def => 'an..35', },
}},
'C011' => { label => 'INFORMATION DETAIL', desc => 'To provide the information details.', parts =>{
    9617 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    9616 => { pos => '040', def => 'an..256', },
}},
'C012' => { label => 'PROCESSING INDICATOR', desc => 'Identification of the processing indicator.', parts =>{
    7365 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7364 => { pos => '040', def => 'an..35', },
}},
'C019' => { label => 'PAYMENT TERMS', desc => 'Terms of payment information.', parts =>{
    4277 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    4276 => { pos => '040', def => 'an..35', },
}},
'C030' => { label => 'EVENT TYPE', desc => 'To specify the type of event.', parts =>{
    9171 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    9170 => { pos => '040', def => 'an..70', },
}},
'C040' => { label => 'CARRIER', desc => 'Identification of a carrier by code and/or by name. Code preferred.', parts =>{
    3127 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    3126 => { pos => '040', def => 'an..35', },
}},
'C042' => { label => 'NATIONALITY DETAILS', desc => 'To specify a nationality.', parts =>{
    3293 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    3292 => { pos => '040', def => 'a..35' , },
}},
'C045' => { label => 'BILL LEVEL IDENTIFICATION', desc => 'A sequenced collection of facetted codes used for multiple indexing purposes.', parts =>{
    7436 => { pos => '010', def => 'an..17', },
    7438 => { pos => '020', def => 'an..17', },
    7440 => { pos => '030', def => 'an..17', },
    7442 => { pos => '040', def => 'an..17', },
    7444 => { pos => '050', def => 'an..17', },
    7446 => { pos => '060', def => 'an..17', },
}},
'C049' => { label => 'REMUNERATION TYPE IDENTIFICATION', desc => 'Identification of the type of a remuneration.', parts =>{
    5315 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    5314 => { pos => '040', def => 'an..35', },
    5314 => { pos => '050', def => 'an..35', },
}},
'C056' => { label => 'CONTACT DETAILS', desc => 'Code and/or name of a contact such as a department or employee. Code preferred.', parts =>{
    3413 => { pos => '010', def => 'an..17', },
    3412 => { pos => '020', def => 'an..256', },
}},
'C058' => { label => 'NAME AND ADDRESS', desc => 'Unstructured name and address: one to five lines.', parts =>{
    3124 => { pos => '010', def => 'an..35', mandatory => 1, },
    3124 => { pos => '020', def => 'an..35', },
    3124 => { pos => '030', def => 'an..35', },
    3124 => { pos => '040', def => 'an..35', },
    3124 => { pos => '050', def => 'an..35', },
}},
'C059' => { label => 'STREET', desc => 'Street address and/or PO Box number in a structured address: one to four lines.', parts =>{
    3042 => { pos => '010', def => 'an..35', mandatory => 1, },
    3042 => { pos => '020', def => 'an..35', },
    3042 => { pos => '030', def => 'an..35', },
    3042 => { pos => '040', def => 'an..35', },
}},
'C063' => { label => 'EVENT IDENTIFICATION', desc => 'To identify an event.', parts =>{
    9173 => { pos => '010', def => 'an..35', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    9172 => { pos => '040', def => 'an..256', },
}},
'C076' => { label => 'COMMUNICATION CONTACT', desc => 'Communication number of a department or employee in a specified channel.', parts =>{
    3148 => { pos => '010', def => 'an..512', mandatory => 1, },
    3155 => { pos => '020', def => 'an..3' , mandatory => 1, },
}},
'C077' => { label => 'FILE IDENTIFICATION', desc => 'To identify a file.', parts =>{
    1508 => { pos => '010', def => 'an..35', },
    7008 => { pos => '020', def => 'an..256', },
}},
'C078' => { label => 'ACCOUNT HOLDER IDENTIFICATION', desc => 'Identification of an account holder by account number and/or account holder name in one or two lines. Number preferred.', parts =>{
    3194 => { pos => '010', def => 'an..35', },
    3192 => { pos => '020', def => 'an..35', },
    3192 => { pos => '030', def => 'an..35', },
    6345 => { pos => '040', def => 'an..3' , },
}},
'C079' => { label => 'COMPUTER ENVIRONMENT IDENTIFICATION', desc => 'To identify parts of a computer environment.', parts =>{
    1511 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    1510 => { pos => '040', def => 'an..35', },
    1056 => { pos => '050', def => 'an..9' , },
    1058 => { pos => '060', def => 'an..9' , },
    7402 => { pos => '070', def => 'an..35', },
}},
'C080' => { label => 'PARTY NAME', desc => 'Identification of a transaction party by name, one to five lines. Party name may be formatted.', parts =>{
    3036 => { pos => '010', def => 'an..70', mandatory => 1, },
    3036 => { pos => '020', def => 'an..70', },
    3036 => { pos => '030', def => 'an..70', },
    3036 => { pos => '040', def => 'an..70', },
    3036 => { pos => '050', def => 'an..70', },
    3045 => { pos => '060', def => 'an..3' , },
}},
'C082' => { label => 'PARTY IDENTIFICATION DETAILS', desc => 'Identification of a transaction party by code.', parts =>{
    3039 => { pos => '010', def => 'an..35', mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C085' => { label => 'MARITAL STATUS DETAILS', desc => 'To specify the marital status of a person.', parts =>{
    3479 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    3478 => { pos => '040', def => 'an..35', },
}},
'C088' => { label => 'INSTITUTION IDENTIFICATION', desc => 'Identification of a financial institution by code branch number, or name and name of place. Code or branch number preferred.', parts =>{
    3433 => { pos => '010', def => 'an..11', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    3434 => { pos => '040', def => 'an..17', },
    1131 => { pos => '050', def => 'an..17', },
    3055 => { pos => '060', def => 'an..3' , },
    3432 => { pos => '070', def => 'an..70', },
    3436 => { pos => '080', def => 'an..70', },
}},
'C090' => { label => 'ADDRESS DETAILS', desc => 'To specify the details of an address.', parts =>{
    3477 => { pos => '010', def => 'an..3' , mandatory => 1, },
    3286 => { pos => '020', def => 'an..70', mandatory => 1, },
    3286 => { pos => '030', def => 'an..70', },
    3286 => { pos => '040', def => 'an..70', },
    3286 => { pos => '050', def => 'an..70', },
    3286 => { pos => '060', def => 'an..70', },
}},
'C099' => { label => 'FILE DETAILS', desc => 'To define details relevant to a file.', parts =>{
    1516 => { pos => '010', def => 'an..17', mandatory => 1, },
    1056 => { pos => '020', def => 'an..9' , },
    1503 => { pos => '030', def => 'an..3' , },
    1502 => { pos => '040', def => 'an..35', },
}},
'C100' => { label => 'TERMS OF DELIVERY OR TRANSPORT', desc => 'Terms of delivery or transport code from a specified source.', parts =>{
    4053 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    4052 => { pos => '040', def => 'an..70', },
    4052 => { pos => '050', def => 'an..70', },
}},
'C101' => { label => 'RELIGION DETAILS', desc => 'To specify the religion of a person.', parts =>{
    3483 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    3482 => { pos => '040', def => 'an..35', },
}},
'C106' => { label => 'DOCUMENT/MESSAGE IDENTIFICATION', desc => 'Identification of a document/message by its number and eventually its version or revision.', parts =>{
    1004 => { pos => '010', def => 'an..70', },
    1056 => { pos => '020', def => 'an..9' , },
    1060 => { pos => '030', def => 'an..6' , },
}},
'C107' => { label => 'TEXT REFERENCE', desc => 'Coded reference to a standard text and its source.', parts =>{
    4441 => { pos => '010', def => 'an..17', mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C108' => { label => 'TEXT LITERAL', desc => 'Free text; one to five lines.', parts =>{
    4440 => { pos => '010', def => 'an..512', mandatory => 1, },
    4440 => { pos => '020', def => 'an..512', },
    4440 => { pos => '030', def => 'an..512', },
    4440 => { pos => '040', def => 'an..512', },
    4440 => { pos => '050', def => 'an..512', },
}},
'C128' => { label => 'RATE DETAILS', desc => 'Rate per unit and rate basis.', parts =>{
    5419 => { pos => '010', def => 'an..3' , mandatory => 1, },
    5420 => { pos => '020', def => 'n..15' , mandatory => 1, },
    5284 => { pos => '030', def => 'n..9'  , },
    6411 => { pos => '040', def => 'an..8' , },
}},
'C138' => { label => 'PRICE MULTIPLIER INFORMATION', desc => 'Price multiplier and its identification.', parts =>{
    5394 => { pos => '010', def => 'n..12' , mandatory => 1, },
    5393 => { pos => '020', def => 'an..3' , },
}},
'C174' => { label => 'VALUE/RANGE', desc => 'Measurement value and relevant minimum and maximum values of the measurement range.', parts =>{
    6411 => { pos => '010', def => 'an..8' , mandatory => 1, },
    6314 => { pos => '020', def => 'an..18', },
    6162 => { pos => '030', def => 'n..18' , },
    6152 => { pos => '040', def => 'n..18' , },
    6432 => { pos => '050', def => 'n..2'  , },
}},
'C186' => { label => 'QUANTITY DETAILS', desc => 'Quantity information in a transaction, qualified when relevant.', parts =>{
    6063 => { pos => '010', def => 'an..3' , mandatory => 1, },
    6060 => { pos => '020', def => 'an..35', mandatory => 1, },
    6411 => { pos => '030', def => 'an..8' , },
}},
'C200' => { label => 'CHARGE', desc => 'Identification of a charge by code and/or by name.', parts =>{
    8023 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    8022 => { pos => '040', def => 'an..26', },
    4237 => { pos => '050', def => 'an..3' , },
    7140 => { pos => '060', def => 'an..35', },
}},
'C202' => { label => 'PACKAGE TYPE', desc => 'Type of package by name or by code from a specified source.', parts =>{
    7065 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7064 => { pos => '040', def => 'an..35', },
}},
'C203' => { label => 'RATE/TARIFF CLASS', desc => 'Identification of the applicable rate/tariff class.', parts =>{
    5243 => { pos => '010', def => 'an..9' , mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    5242 => { pos => '040', def => 'an..35', },
    5275 => { pos => '050', def => 'an..6' , },
    1131 => { pos => '060', def => 'an..17', },
    3055 => { pos => '070', def => 'an..3' , },
    5275 => { pos => '080', def => 'an..6' , },
    1131 => { pos => '090', def => 'an..17', },
    3055 => { pos => '100', def => 'an..3' , },
}},
'C205' => { label => 'HAZARD CODE', desc => 'The identification of the dangerous goods in code.', parts =>{
    8351 => { pos => '010', def => 'an..7' , mandatory => 1, },
    8078 => { pos => '020', def => 'an..7' , },
    8092 => { pos => '030', def => 'an..10', },
}},
'C206' => { label => 'IDENTIFICATION NUMBER', desc => 'The identification of an object.', parts =>{
    7402 => { pos => '010', def => 'an..35', mandatory => 1, },
    7405 => { pos => '020', def => 'an..3' , },
    4405 => { pos => '030', def => 'an..3' , },
}},
'C208' => { label => 'IDENTITY NUMBER RANGE', desc => 'Goods item identification numbers, start and end of consecutively numbered range.', parts =>{
    7402 => { pos => '010', def => 'an..35', mandatory => 1, },
    7402 => { pos => '020', def => 'an..35', },
}},
'C210' => { label => 'MARKS & LABELS', desc => 'Shipping marks on packages in free text; one to ten lines.', parts =>{
    7102 => { pos => '010', def => 'an..35', mandatory => 1, },
    7102 => { pos => '020', def => 'an..35', },
    7102 => { pos => '030', def => 'an..35', },
    7102 => { pos => '040', def => 'an..35', },
    7102 => { pos => '050', def => 'an..35', },
    7102 => { pos => '060', def => 'an..35', },
    7102 => { pos => '070', def => 'an..35', },
    7102 => { pos => '080', def => 'an..35', },
    7102 => { pos => '090', def => 'an..35', },
    7102 => { pos => '100', def => 'an..35', },
}},
'C211' => { label => 'DIMENSIONS', desc => 'Specification of the dimensions of a transportable unit.', parts =>{
    6411 => { pos => '010', def => 'an..8' , mandatory => 1, },
    6168 => { pos => '020', def => 'n..15' , },
    6140 => { pos => '030', def => 'n..15' , },
    6008 => { pos => '040', def => 'n..15' , },
}},
'C212' => { label => 'ITEM NUMBER IDENTIFICATION', desc => 'Goods identification for a specified source.', parts =>{
    7140 => { pos => '010', def => 'an..35', },
    7143 => { pos => '020', def => 'an..3' , },
    1131 => { pos => '030', def => 'an..17', },
    3055 => { pos => '040', def => 'an..3' , },
}},
'C213' => { label => 'NUMBER AND TYPE OF PACKAGES', desc => 'Number and type of individual parts of a shipment.', parts =>{
    7224 => { pos => '010', def => 'n..8'  , },
    7065 => { pos => '020', def => 'an..17', },
    1131 => { pos => '030', def => 'an..17', },
    3055 => { pos => '040', def => 'an..3' , },
    7064 => { pos => '050', def => 'an..35', },
    7233 => { pos => '060', def => 'an..3' , },
}},
'C214' => { label => 'SPECIAL SERVICES IDENTIFICATION', desc => 'Identification of a special service by a code from a specified source or by description.', parts =>{
    7161 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7160 => { pos => '040', def => 'an..35', },
    7160 => { pos => '050', def => 'an..35', },
}},
'C215' => { label => 'SEAL ISSUER', desc => 'Identification of the issuer of a seal on equipment either by code or by name.', parts =>{
    9303 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    9302 => { pos => '040', def => 'an..35', },
}},
'C218' => { label => 'HAZARDOUS MATERIAL', desc => 'To specify a hazardous material.', parts =>{
    7419 => { pos => '010', def => 'an..7' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7418 => { pos => '040', def => 'an..35', },
}},
'C219' => { label => 'MOVEMENT TYPE', desc => 'Description of type of service for movement of cargo.', parts =>{
    8335 => { pos => '010', def => 'an..3' , },
    8334 => { pos => '020', def => 'an..35', },
}},
'C220' => { label => 'MODE OF TRANSPORT', desc => 'Method of transport code or name. Code preferred.', parts =>{
    8067 => { pos => '010', def => 'an..3' , },
    8066 => { pos => '020', def => 'an..17', },
}},
'C222' => { label => 'TRANSPORT IDENTIFICATION', desc => 'Code and/or name identifying the means of transport.', parts =>{
    8213 => { pos => '010', def => 'an..35', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    8212 => { pos => '040', def => 'an..70', },
    8453 => { pos => '050', def => 'an..3' , },
}},
'C223' => { label => 'DANGEROUS GOODS SHIPMENT FLASHPOINT', desc => 'Temperature at which a vapor can be ignited as per ISO 1523/73.', parts =>{
    7106 => { pos => '010', def => 'n3'    , },
    6411 => { pos => '020', def => 'an..8' , },
}},
'C224' => { label => 'EQUIPMENT SIZE AND TYPE', desc => 'Code and or name identifying size and type of equipment. Code preferred.', parts =>{
    8155 => { pos => '010', def => 'an..10', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    8154 => { pos => '040', def => 'an..35', },
}},
'C229' => { label => 'CHARGE CATEGORY', desc => 'Identification of a category or a zone of charges.', parts =>{
    5237 => { pos => '010', def => 'an..3' , mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C231' => { label => 'METHOD OF PAYMENT', desc => 'Code identifying the method of payment.', parts =>{
    4215 => { pos => '010', def => 'an..3' , mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C232' => { label => 'GOVERNMENT ACTION', desc => 'Function: To indicate the requirement for a specific governmental action and/or procedure or which specific procedure is valid for a specific part of the transport and cross-border transactions. (Note the red portion as change in the segment description.).', parts =>{
    9415 => { pos => '010', def => 'an..3' , },
    9411 => { pos => '020', def => 'an..3' , },
    9417 => { pos => '030', def => 'an..3' , },
    9353 => { pos => '040', def => 'an..3' , },
}},
'C233' => { label => 'SERVICE', desc => 'To identify a service (which may constitute an additional component to a basic contract).', parts =>{
    7273 => { pos => '010', def => 'an..3' , mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7273 => { pos => '040', def => 'an..3' , },
    1131 => { pos => '050', def => 'an..17', },
    3055 => { pos => '060', def => 'an..3' , },
}},
'C234' => { label => 'UNDG INFORMATION', desc => 'Information on dangerous goods, taken from the United Nations Dangerous Goods classification.', parts =>{
    7124 => { pos => '010', def => 'n4'    , },
    7088 => { pos => '020', def => 'an..8' , },
}},
'C235' => { label => 'HAZARD IDENTIFICATION PLACARD DETAILS', desc => 'These numbers appear on the hazard identification placard required on the means of transport.', parts =>{
    8158 => { pos => '010', def => 'an..4' , },
    8186 => { pos => '020', def => 'an4'   , },
}},
'C236' => { label => 'DANGEROUS GOODS LABEL', desc => 'Markings identifying the type of hazardous goods and similar information.', parts =>{
    8246 => { pos => '010', def => 'an..4' , },
    8246 => { pos => '020', def => 'an..4' , },
    8246 => { pos => '030', def => 'an..4' , },
    8246 => { pos => '040', def => 'an..4' , },
}},
'C237' => { label => 'EQUIPMENT IDENTIFICATION', desc => 'Marks (letters/numbers) identifying equipment.', parts =>{
    8260 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    3207 => { pos => '040', def => 'an..3' , },
}},
'C239' => { label => 'TEMPERATURE SETTING', desc => 'The temperature under which the goods are (to be) stored or shipped.', parts =>{
    6246 => { pos => '010', def => 'n..15' , },
    6411 => { pos => '020', def => 'an..8' , },
}},
'C240' => { label => 'CHARACTERISTIC DESCRIPTION', desc => 'To provide a description of a characteristic.', parts =>{
    7037 => { pos => '010', def => 'an..17', mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7036 => { pos => '040', def => 'an..35', },
    7036 => { pos => '050', def => 'an..35', },
}},
'C241' => { label => 'DUTY/TAX/FEE TYPE', desc => 'Code and/or name identifying duty, tax or fee.', parts =>{
    5153 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    5152 => { pos => '040', def => 'an..35', },
}},
'C242' => { label => 'PROCESS TYPE AND DESCRIPTION', desc => 'Identification of process type and description.', parts =>{
    7187 => { pos => '010', def => 'an..17', mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7186 => { pos => '040', def => 'an..35', },
    7186 => { pos => '050', def => 'an..35', },
}},
'C243' => { label => 'DUTY/TAX/FEE DETAIL', desc => 'Rate of duty/tax/fee applicable to commodities or of tax applicable to services.', parts =>{
    5279 => { pos => '010', def => 'an..7' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    5278 => { pos => '040', def => 'an..17', },
    5273 => { pos => '050', def => 'an..12', },
    1131 => { pos => '060', def => 'an..17', },
    3055 => { pos => '070', def => 'an..3' , },
}},
'C244' => { label => 'TEST METHOD', desc => 'Specification of the test method employed.', parts =>{
    4415 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    4416 => { pos => '040', def => 'an..70', },
}},
'C246' => { label => 'CUSTOMS IDENTITY CODES', desc => 'Specification of goods in terms of customs identity.', parts =>{
    7361 => { pos => '010', def => 'an..18', mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C250' => { label => 'USAGE', desc => 'Code or name describing usage.', parts =>{
    7521 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7522 => { pos => '040', def => 'an..256', },
}},
'C270' => { label => 'CONTROL', desc => 'Control total for checking integrity of a message or part of a message.', parts =>{
    6069 => { pos => '010', def => 'an..3' , mandatory => 1, },
    6066 => { pos => '020', def => 'n..18' , mandatory => 1, },
    6411 => { pos => '030', def => 'an..8' , },
}},
'C272' => { label => 'ITEM CHARACTERISTIC', desc => 'To provide the characteristic of the item being described.', parts =>{
    7081 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C273' => { label => 'ITEM DESCRIPTION', desc => 'Description of an item.', parts =>{
    7009 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7008 => { pos => '040', def => 'an..256', },
    7008 => { pos => '050', def => 'an..256', },
    3453 => { pos => '060', def => 'an..3' , },
}},
'C279' => { label => 'QUANTITY DIFFERENCE INFORMATION', desc => 'Information on quantity difference.', parts =>{
    6064 => { pos => '010', def => 'n..15' , mandatory => 1, },
    6063 => { pos => '020', def => 'an..3' , },
}},
'C280' => { label => 'RANGE', desc => 'Range minimum and maximum limits.', parts =>{
    6411 => { pos => '010', def => 'an..8' , mandatory => 1, },
    6162 => { pos => '020', def => 'n..18' , },
    6152 => { pos => '030', def => 'n..18' , },
}},
'C286' => { label => 'SEQUENCE INFORMATION', desc => 'Identification of a sequence and source for sequencing.', parts =>{
    1050 => { pos => '010', def => 'an..10', mandatory => 1, },
    1159 => { pos => '020', def => 'an..3' , },
    1131 => { pos => '030', def => 'an..17', },
    3055 => { pos => '040', def => 'an..3' , },
}},
'C288' => { label => 'PRODUCT GROUP', desc => 'To give product group information.', parts =>{
    5389 => { pos => '010', def => 'an..25', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    5388 => { pos => '040', def => 'an..35', },
}},
'C289' => { label => 'TUNNEL RESTRICTION', desc => 'To specify a restriction for transport through tunnels.', parts =>{
    8461 => { pos => '010', def => 'an..6' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C329' => { label => 'PATTERN DESCRIPTION', desc => 'Shipment, delivery or production interval pattern and timing.', parts =>{
    2013 => { pos => '010', def => 'an..3' , },
    2015 => { pos => '020', def => 'an..3' , },
    2017 => { pos => '030', def => 'an..3' , },
}},
'C330' => { label => 'INSURANCE COVER TYPE', desc => 'To provide the insurance cover type.', parts =>{
    4497 => { pos => '010', def => 'an..3' , mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C331' => { label => 'INSURANCE COVER DETAILS', desc => 'To provide the insurance cover details.', parts =>{
    4495 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    4494 => { pos => '040', def => 'an..35', },
    4494 => { pos => '050', def => 'an..35', },
}},
'C332' => { label => 'SALES CHANNEL IDENTIFICATION', desc => 'Identification of sales channel for marketing data, sales, forecast, planning...', parts =>{
    3496 => { pos => '010', def => 'an..17', mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C333' => { label => 'INFORMATION REQUEST', desc => 'To specify the information requested in a responding message.', parts =>{
    4511 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    4510 => { pos => '040', def => 'an..35', },
}},
'C401' => { label => 'EXCESS TRANSPORTATION INFORMATION', desc => 'To provide details of reason for, and responsibility for, use of transportation other than normally utilized.', parts =>{
    8457 => { pos => '010', def => 'an..3' , mandatory => 1, },
    8459 => { pos => '020', def => 'an..3' , mandatory => 1, },
    7130 => { pos => '030', def => 'an..17', },
}},
'C402' => { label => 'PACKAGE TYPE IDENTIFICATION', desc => 'Identification of the form in which goods are described.', parts =>{
    7077 => { pos => '010', def => 'an..3' , mandatory => 1, },
    7064 => { pos => '020', def => 'an..35', mandatory => 1, },
    7143 => { pos => '030', def => 'an..3' , },
    7064 => { pos => '040', def => 'an..35', },
    7143 => { pos => '050', def => 'an..3' , },
}},
'C501' => { label => 'PERCENTAGE DETAILS', desc => 'Percentage relating to a specified basis.', parts =>{
    5245 => { pos => '010', def => 'an..3' , mandatory => 1, },
    5482 => { pos => '020', def => 'n..10' , },
    5249 => { pos => '030', def => 'an..3' , },
    1131 => { pos => '040', def => 'an..17', },
    3055 => { pos => '050', def => 'an..3' , },
}},
'C502' => { label => 'MEASUREMENT DETAILS', desc => 'Identification of measurement type.', parts =>{
    6313 => { pos => '010', def => 'an..3' , },
    6321 => { pos => '020', def => 'an..3' , },
    6155 => { pos => '030', def => 'an..17', },
    6154 => { pos => '040', def => 'an..70', },
}},
'C503' => { label => 'DOCUMENT/MESSAGE DETAILS', desc => 'Identification of document/message by number, status, source and/or language.', parts =>{
    1004 => { pos => '010', def => 'an..70', },
    1373 => { pos => '020', def => 'an..3' , },
    1366 => { pos => '030', def => 'an..70', },
    3453 => { pos => '040', def => 'an..3' , },
    1056 => { pos => '050', def => 'an..9' , },
    1060 => { pos => '060', def => 'an..6' , },
}},
'C504' => { label => 'CURRENCY DETAILS', desc => 'The usage to which a currency relates.', parts =>{
    6347 => { pos => '010', def => 'an..3' , mandatory => 1, },
    6345 => { pos => '020', def => 'an..3' , },
    6343 => { pos => '030', def => 'an..3' , },
    6348 => { pos => '040', def => 'n..4'  , },
}},
'C506' => { label => 'REFERENCE', desc => 'Identification of a reference.', parts =>{
    1153 => { pos => '010', def => 'an..3' , mandatory => 1, },
    1154 => { pos => '020', def => 'an..70', },
    1156 => { pos => '030', def => 'an..6' , },
    1056 => { pos => '040', def => 'an..9' , },
    1060 => { pos => '050', def => 'an..6' , },
}},
'C507' => { label => 'DATE/TIME/PERIOD', desc => 'Date and/or time, or period relevant to the specified date/time/period type.', parts =>{
    2005 => { pos => '010', def => 'an..3' , mandatory => 1, },
    2380 => { pos => '020', def => 'an..35', },
    2379 => { pos => '030', def => 'an..3' , },
}},
'C508' => { label => 'LANGUAGE DETAILS', desc => 'To identify a language.', parts =>{
    3453 => { pos => '010', def => 'an..3' , },
    3452 => { pos => '020', def => 'an..35', },
}},
'C509' => { label => 'PRICE INFORMATION', desc => 'Identification of price type, price and related details.', parts =>{
    5125 => { pos => '010', def => 'an..3' , mandatory => 1, },
    5118 => { pos => '020', def => 'n..15' , },
    5375 => { pos => '030', def => 'an..3' , },
    5387 => { pos => '040', def => 'an..3' , },
    5284 => { pos => '050', def => 'n..9'  , },
    6411 => { pos => '060', def => 'an..8' , },
}},
'C512' => { label => 'SIZE DETAILS', desc => 'Information about the number of observations.', parts =>{
    6173 => { pos => '010', def => 'an..3' , },
    6174 => { pos => '020', def => 'n..15' , },
}},
'C514' => { label => 'SAMPLE LOCATION DETAILS', desc => 'Identification of location within the specimen, from which the sample was taken.', parts =>{
    3237 => { pos => '010', def => 'an..3' , },
    3236 => { pos => '020', def => 'an..35', },
}},
'C515' => { label => 'TEST REASON', desc => 'To identify the reason for the test as specified.', parts =>{
    4425 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    4424 => { pos => '040', def => 'an..35', },
}},
'C516' => { label => 'MONETARY AMOUNT', desc => 'Amount of goods or services stated as a monetary amount in a specified currency.', parts =>{
    5025 => { pos => '010', def => 'an..3' , mandatory => 1, },
    5004 => { pos => '020', def => 'n..35' , },
    6345 => { pos => '030', def => 'an..3' , },
    6343 => { pos => '040', def => 'an..3' , },
    4405 => { pos => '050', def => 'an..3' , },
}},
'C517' => { label => 'LOCATION IDENTIFICATION', desc => 'Identification of a location by code or name.', parts =>{
    3225 => { pos => '010', def => 'an..35', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    3224 => { pos => '040', def => 'an..256', },
}},
'C519' => { label => 'RELATED LOCATION ONE IDENTIFICATION', desc => 'Identification the first related location by code or name.', parts =>{
    3223 => { pos => '010', def => 'an..35', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    3222 => { pos => '040', def => 'an..70', },
}},
'C521' => { label => 'BUSINESS FUNCTION', desc => 'To specify a business reason.', parts =>{
    4027 => { pos => '010', def => 'an..3' , mandatory => 1, },
    4025 => { pos => '020', def => 'an..3' , mandatory => 1, },
    1131 => { pos => '030', def => 'an..17', },
    3055 => { pos => '040', def => 'an..3' , },
    4022 => { pos => '050', def => 'an..70', },
}},
'C522' => { label => 'INSTRUCTION', desc => 'To specify an instruction.', parts =>{
    4403 => { pos => '010', def => 'an..3' , mandatory => 1, },
    4401 => { pos => '020', def => 'an..3' , },
    1131 => { pos => '030', def => 'an..17', },
    3055 => { pos => '040', def => 'an..3' , },
    4400 => { pos => '050', def => 'an..35', },
}},
'C523' => { label => 'NUMBER OF UNIT DETAILS', desc => 'Identification of number of units and its purpose.', parts =>{
    6350 => { pos => '010', def => 'n..15' , },
    6353 => { pos => '020', def => 'an..3' , },
}},
'C524' => { label => 'HANDLING INSTRUCTIONS', desc => 'Instruction for the handling of goods, products or articles in shipment, storage etc.', parts =>{
    4079 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    4078 => { pos => '040', def => 'an..512', },
}},
'C525' => { label => 'PURPOSE OF CONVEYANCE CALL', desc => 'Description of the purpose of the call of the conveyance.', parts =>{
    8025 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    8024 => { pos => '040', def => 'an..35', },
}},
'C526' => { label => 'FREQUENCY DETAILS', desc => 'Number of samples collected per specified unit of measure.', parts =>{
    6071 => { pos => '010', def => 'an..3' , mandatory => 1, },
    6072 => { pos => '020', def => 'n..9'  , },
    6411 => { pos => '030', def => 'an..8' , },
}},
'C527' => { label => 'STATISTICAL DETAILS', desc => 'Specifications related to statistical measurements.', parts =>{
    6314 => { pos => '010', def => 'an..18', },
    6411 => { pos => '020', def => 'an..8' , },
    6313 => { pos => '030', def => 'an..3' , },
    6321 => { pos => '040', def => 'an..3' , },
}},
'C528' => { label => 'COMMODITY/RATE DETAIL', desc => 'Identification of commodity/rates.', parts =>{
    7357 => { pos => '010', def => 'an..18', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C531' => { label => 'PACKAGING DETAILS', desc => 'Packaging level and details, terms and conditions.', parts =>{
    7075 => { pos => '010', def => 'an..3' , },
    7233 => { pos => '020', def => 'an..3' , },
    7073 => { pos => '030', def => 'an..3' , },
}},
'C532' => { label => 'RETURNABLE PACKAGE DETAILS', desc => 'Indication of responsibility for payment and load contents of returnable packages.', parts =>{
    8395 => { pos => '010', def => 'an..3' , },
    8393 => { pos => '020', def => 'an..3' , },
}},
'C533' => { label => 'DUTY/TAX/FEE ACCOUNT DETAIL', desc => 'Indication of account reference for duties, taxes and/or fees.', parts =>{
    5289 => { pos => '010', def => 'an..6' , mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C534' => { label => 'PAYMENT INSTRUCTION DETAILS', desc => 'Indication of method of payment employed or to be employed.', parts =>{
    4439 => { pos => '010', def => 'an..3' , },
    4431 => { pos => '020', def => 'an..3' , },
    4461 => { pos => '030', def => 'an..3' , },
    1131 => { pos => '040', def => 'an..17', },
    3055 => { pos => '050', def => 'an..3' , },
    4435 => { pos => '060', def => 'an..3' , },
}},
'C536' => { label => 'CONTRACT AND CARRIAGE CONDITION', desc => 'To identify a contract and carriage condition.', parts =>{
    4065 => { pos => '010', def => 'an..3' , mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C537' => { label => 'TRANSPORT PRIORITY', desc => 'To indicate the priority of requested transport service.', parts =>{
    4219 => { pos => '010', def => 'an..3' , mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C543' => { label => 'AGREEMENT TYPE IDENTIFICATION', desc => 'Identification of specific agreement type by code or name.', parts =>{
    7431 => { pos => '010', def => 'an..3' , mandatory => 1, },
    7433 => { pos => '020', def => 'an..3' , },
    1131 => { pos => '030', def => 'an..17', },
    3055 => { pos => '040', def => 'an..3' , },
    7434 => { pos => '050', def => 'an..70', },
}},
'C545' => { label => 'INDEX IDENTIFICATION', desc => 'To identify an index.', parts =>{
    5013 => { pos => '010', def => 'an..3' , mandatory => 1, },
    5027 => { pos => '020', def => 'an..17', },
    1131 => { pos => '030', def => 'an..17', },
    3055 => { pos => '040', def => 'an..3' , },
}},
'C546' => { label => 'INDEX VALUE', desc => 'To identify the value of an index.', parts =>{
    5030 => { pos => '010', def => 'an..35', mandatory => 1, },
    5039 => { pos => '020', def => 'an..3' , },
}},
'C549' => { label => 'MONETARY AMOUNT FUNCTION', desc => 'To identify the function of a monetary amount.', parts =>{
    5007 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    5006 => { pos => '040', def => 'an..70', },
}},
'C550' => { label => 'REQUIREMENT/CONDITION IDENTIFICATION', desc => 'To identify the specific rule/condition requirement.', parts =>{
    7295 => { pos => '010', def => 'an..17', mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7294 => { pos => '040', def => 'an..35', },
}},
'C551' => { label => 'BANK OPERATION', desc => 'Identification of a bank operation by code.', parts =>{
    4383 => { pos => '010', def => 'an..3' , mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C552' => { label => 'ALLOWANCE/CHARGE INFORMATION', desc => 'Identification of allowance/charge information by number and/or code.', parts =>{
    1230 => { pos => '010', def => 'an..35', },
    5189 => { pos => '020', def => 'an..3' , },
}},
'C553' => { label => 'RELATED LOCATION TWO IDENTIFICATION', desc => 'Identification of second related location by code or name.', parts =>{
    3233 => { pos => '010', def => 'an..35', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    3232 => { pos => '040', def => 'an..70', },
}},
'C554' => { label => 'RATE/TARIFF CLASS DETAIL', desc => 'Identification of the applicable rate/tariff class.', parts =>{
    5243 => { pos => '010', def => 'an..9' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C555' => { label => 'STATUS', desc => 'To specify a status.', parts =>{
    4405 => { pos => '010', def => 'an..3' , mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    4404 => { pos => '040', def => 'an..35', },
}},
'C556' => { label => 'STATUS REASON', desc => 'To specify the reason for a status.', parts =>{
    9013 => { pos => '010', def => 'an..3' , mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    9012 => { pos => '040', def => 'an..256', },
}},
'C564' => { label => 'PHYSICAL OR LOGICAL STATE INFORMATION', desc => 'To give information in coded or clear text form on the physical or logical state.', parts =>{
    7007 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7006 => { pos => '040', def => 'an..70', },
}},
'C585' => { label => 'PRIORITY DETAILS', desc => 'To indicate a priority.', parts =>{
    4037 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    4036 => { pos => '040', def => 'an..35', },
}},
'C593' => { label => 'ACCOUNT IDENTIFICATION', desc => 'Identification of an account.', parts =>{
    1147 => { pos => '010', def => 'an..35', mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    1148 => { pos => '040', def => 'an..17', },
    1146 => { pos => '050', def => 'an..35', },
    1146 => { pos => '060', def => 'an..35', },
    6345 => { pos => '070', def => 'an..3' , },
}},
'C595' => { label => 'ACCOUNTING JOURNAL IDENTIFICATION', desc => 'Identification of an accounting journal.', parts =>{
    1171 => { pos => '010', def => 'an..17', mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    1170 => { pos => '040', def => 'an..35', },
}},
'C596' => { label => 'ACCOUNTING ENTRY TYPE DETAILS', desc => 'Identification of the type of entry included in an accounting journal.', parts =>{
    4475 => { pos => '010', def => 'an..17', mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    4474 => { pos => '040', def => 'an..35', },
}},
'C601' => { label => 'STATUS CATEGORY', desc => 'To specify the category of the status.', parts =>{
    9015 => { pos => '010', def => 'an..3' , mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C701' => { label => 'ERROR POINT DETAILS', desc => 'Indication of the point of error in a message.', parts =>{
    1049 => { pos => '010', def => 'an..3' , },
    1052 => { pos => '020', def => 'an..35', },
    1054 => { pos => '030', def => 'n..6'  , },
}},
'C702' => { label => 'CODE SET IDENTIFICATION', desc => 'To identify a code set.', parts =>{
    9150 => { pos => '010', def => 'an..4' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C703' => { label => 'NATURE OF CARGO', desc => 'Rough classification of a type of cargo.', parts =>{
    7085 => { pos => '010', def => 'an..3' , mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C709' => { label => 'MESSAGE IDENTIFIER', desc => 'Identification of the message.', parts =>{
    1003 => { pos => '010', def => 'an..6' , mandatory => 1, },
    1056 => { pos => '020', def => 'an..9' , },
    1058 => { pos => '030', def => 'an..9' , },
    1476 => { pos => '040', def => 'an..2' , },
    1523 => { pos => '050', def => 'an..6' , },
    1060 => { pos => '060', def => 'an..6' , },
    1373 => { pos => '070', def => 'an..3' , },
}},
'C770' => { label => 'ARRAY CELL DETAILS', desc => 'To contain the data for a contiguous set of cells in an array.', parts =>{
    9424 => { pos => '010', def => 'an..512', },
}},
'C778' => { label => 'POSITION IDENTIFICATION', desc => 'To identify the position of an object in a structure containing the object.', parts =>{
    7164 => { pos => '010', def => 'an..35', },
    1050 => { pos => '020', def => 'an..10', },
}},
'C779' => { label => 'ARRAY STRUCTURE IDENTIFICATION', desc => 'The identification of an array structure.', parts =>{
    9428 => { pos => '010', def => 'an..35', mandatory => 1, },
    7405 => { pos => '020', def => 'an..3' , },
}},
'C780' => { label => 'VALUE LIST IDENTIFICATION', desc => 'The identification of a coded or non coded value list.', parts =>{
    1518 => { pos => '010', def => 'an..35', mandatory => 1, },
    7405 => { pos => '020', def => 'an..3' , },
}},
'C782' => { label => 'DATA SET IDENTIFICATION', desc => 'The identification of a data set.', parts =>{
    1520 => { pos => '010', def => 'an..35', mandatory => 1, },
    7405 => { pos => '020', def => 'an..3' , },
}},
'C783' => { label => 'FOOTNOTE SET IDENTIFICATION', desc => 'The identification of a set of footnotes.', parts =>{
    9430 => { pos => '010', def => 'an..35', mandatory => 1, },
    7405 => { pos => '020', def => 'an..3' , },
}},
'C784' => { label => 'FOOTNOTE IDENTIFICATION', desc => 'The identification of a footnote.', parts =>{
    9432 => { pos => '010', def => 'an..35', mandatory => 1, },
    7405 => { pos => '020', def => 'an..3' , },
}},
'C785' => { label => 'STATISTICAL CONCEPT IDENTIFICATION', desc => 'The identification of a statistical concept.', parts =>{
    6434 => { pos => '010', def => 'an..35', mandatory => 1, },
    7405 => { pos => '020', def => 'an..3' , },
}},
'C786' => { label => 'STRUCTURE COMPONENT IDENTIFICATION', desc => 'The identification of a structure component.', parts =>{
    7512 => { pos => '010', def => 'an..35', mandatory => 1, },
    7405 => { pos => '020', def => 'an..3' , },
}},
'C811' => { label => 'QUESTION DETAILS', desc => 'To specify a question.', parts =>{
    4057 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    4056 => { pos => '040', def => 'an..256', },
}},
'C812' => { label => 'RESPONSE DETAILS', desc => 'To specify a response to a question, in code or text.', parts =>{
    4345 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    4344 => { pos => '040', def => 'an..256', },
}},
'C814' => { label => 'SAFETY SECTION', desc => 'To identify the safety section to which information relates.', parts =>{
    4046 => { pos => '010', def => 'n..2'  , mandatory => 1, },
    4044 => { pos => '020', def => 'an..70', },
}},
'C815' => { label => 'ADDITIONAL SAFETY INFORMATION', desc => 'To identify additional safety information.', parts =>{
    4039 => { pos => '010', def => 'an..3' , mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    4038 => { pos => '040', def => 'an..35', },
}},
'C816' => { label => 'NAME COMPONENT DETAILS', desc => 'To specify a name component.', parts =>{
    3405 => { pos => '010', def => 'an..3' , mandatory => 1, },
    3398 => { pos => '020', def => 'an..256', },
    3401 => { pos => '030', def => 'an..3' , },
    3295 => { pos => '040', def => 'an..3' , },
}},
'C817' => { label => 'ADDRESS USAGE', desc => 'To describe the usage of an address.', parts =>{
    3299 => { pos => '010', def => 'an..3' , },
    3131 => { pos => '020', def => 'an..3' , },
    3475 => { pos => '030', def => 'an..3' , },
}},
'C818' => { label => 'PERSON INHERITED CHARACTERISTIC DETAILS', desc => 'To specify an inherited characteristic of a person.', parts =>{
    3311 => { pos => '010', def => 'an..8' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    3310 => { pos => '040', def => 'an..70', },
}},
'C819' => { label => 'COUNTRY SUBDIVISION DETAILS', desc => 'To specify a country subdivision, such as state, canton, county, prefecture.', parts =>{
    3229 => { pos => '010', def => 'an..9' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    3228 => { pos => '040', def => 'an..70', },
}},
'C820' => { label => 'PREMIUM CALCULATION COMPONENT', desc => 'To identify the component affecting premium calculation.', parts =>{
    4521 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C821' => { label => 'TYPE OF DAMAGE', desc => 'To specify the type of damage to an object.', parts =>{
    7501 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7500 => { pos => '040', def => 'an..35', },
}},
'C822' => { label => 'DAMAGE AREA', desc => 'To specify where the damage is on an object.', parts =>{
    7503 => { pos => '010', def => 'an..4' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7502 => { pos => '040', def => 'an..35', },
}},
'C823' => { label => 'TYPE OF UNIT/COMPONENT', desc => 'To identify the type of unit/component of an object (e.g. lock, door, tyre).', parts =>{
    7505 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7504 => { pos => '040', def => 'an..35', },
}},
'C824' => { label => 'COMPONENT MATERIAL', desc => 'To identify the material of which a component is composed (e.g. steel, plastics).', parts =>{
    7507 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7506 => { pos => '040', def => 'an..35', },
}},
'C825' => { label => 'DAMAGE SEVERITY', desc => 'To specify the severity of damage to an object.', parts =>{
    7509 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7508 => { pos => '040', def => 'an..35', },
}},
'C826' => { label => 'ACTION', desc => 'To indicate an action which has been taken or is to be taken (e.g. in relation to a certain object).', parts =>{
    1229 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    1228 => { pos => '040', def => 'an..35', },
}},
'C827' => { label => 'TYPE OF MARKING', desc => 'Specification of the type of marking that reflects the method that was used and the conventions adhered to for marking (e.g. of packages).', parts =>{
    7511 => { pos => '010', def => 'an..3' , mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C828' => { label => 'CLINICAL INTERVENTION DETAILS', desc => 'To specify a clinical intervention.', parts =>{
    9437 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    9436 => { pos => '040', def => 'an..70', },
}},
'C829' => { label => 'SUB-LINE INFORMATION', desc => 'To provide an indication that a segment or segment group is used to contain sub-line or sub-line item information and to optionally enable the sub-line to be identified.', parts =>{
    5495 => { pos => '010', def => 'an..3' , },
    1082 => { pos => '020', def => 'an..6' , },
}},
'C830' => { label => 'PROCESS IDENTIFICATION DETAILS', desc => 'To identify the details of a specific process.', parts =>{
    7191 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7190 => { pos => '040', def => 'an..70', },
}},
'C831' => { label => 'RESULT DETAILS', desc => 'To specify a value.', parts =>{
    6314 => { pos => '010', def => 'an..18', },
    6321 => { pos => '020', def => 'an..3' , },
    6155 => { pos => '030', def => 'an..17', },
    1131 => { pos => '040', def => 'an..17', },
    3055 => { pos => '050', def => 'an..3' , },
    6154 => { pos => '060', def => 'an..70', },
}},
'C836' => { label => 'CLINICAL INFORMATION DETAILS', desc => 'To specify an item of clinical information.', parts =>{
    6413 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    6412 => { pos => '040', def => 'an..70', },
}},
'C837' => { label => 'CERTAINTY DETAILS', desc => 'To specify the certainty.', parts =>{
    4049 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    4048 => { pos => '040', def => 'an..35', },
}},
'C838' => { label => 'DOSAGE DETAILS', desc => 'To specify a dosage.', parts =>{
    6083 => { pos => '010', def => 'an..8' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    6082 => { pos => '040', def => 'an..70', },
}},
'C839' => { label => 'ATTENDEE CATEGORY', desc => 'To specify the category of the attendee.', parts =>{
    7459 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7458 => { pos => '040', def => 'an..35', },
}},
'C840' => { label => 'ATTENDANCE ADMISSION DETAILS', desc => 'To specify type of admission.', parts =>{
    9445 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    9444 => { pos => '040', def => 'an..35', },
}},
'C841' => { label => 'ATTENDANCE DISCHARGE DETAILS', desc => 'To specify type of discharge.', parts =>{
    9447 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    9446 => { pos => '040', def => 'an..35', },
}},
'C844' => { label => 'ORGANISATION CLASSIFICATION DETAIL', desc => 'To specify details regarding the class of an organisation.', parts =>{
    3083 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    3082 => { pos => '040', def => 'an..70', },
}},
'C848' => { label => 'MEASUREMENT UNIT DETAILS', desc => 'To specify a measurement unit.', parts =>{
    6411 => { pos => '010', def => 'an..8' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    6410 => { pos => '040', def => 'an..35', },
}},
'C849' => { label => 'PARTIES TO INSTRUCTION', desc => 'Identify the sending and receiving parties of the instruction.', parts =>{
    3301 => { pos => '010', def => 'an..35', mandatory => 1, },
    3285 => { pos => '020', def => 'an..35', },
}},
'C850' => { label => 'STATUS OF INSTRUCTION', desc => 'Provides information regarding the status of an instruction.', parts =>{
    4405 => { pos => '010', def => 'an..3' , mandatory => 1, },
    3036 => { pos => '020', def => 'an..70', },
}},
'C851' => { label => 'RISK OBJECT TYPE', desc => 'Specification of a type of risk object.', parts =>{
    7179 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C852' => { label => 'RISK OBJECT SUB-TYPE', desc => 'To provide identification details for a risk object sub-type.', parts =>{
    7177 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7176 => { pos => '040', def => 'an..70', },
}},
'C853' => { label => 'ERROR SEGMENT POINT DETAILS', desc => 'To indicate the exact segment location of an application error within a message.', parts =>{
    9166 => { pos => '010', def => 'an..3' , },
    1050 => { pos => '020', def => 'an..10', },
    1159 => { pos => '030', def => 'an..3' , },
}},
'C878' => { label => 'CHARGE/ALLOWANCE ACCOUNT', desc => 'Identification of the account for charge or allowance.', parts =>{
    3434 => { pos => '010', def => 'an..17', mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    3194 => { pos => '040', def => 'an..35', },
    6345 => { pos => '050', def => 'an..3' , },
}},
'C889' => { label => 'CHARACTERISTIC VALUE', desc => 'To provide the value of a characteristic.', parts =>{
    7111 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7110 => { pos => '040', def => 'an..35', },
    7110 => { pos => '050', def => 'an..35', },
}},
'C901' => { label => 'APPLICATION ERROR DETAIL', desc => 'Code assigned by the recipient of a message to indicate a data validation error condition.', parts =>{
    9321 => { pos => '010', def => 'an..8' , mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C941' => { label => 'RELATIONSHIP', desc => 'Identification and/or description of a relationship.', parts =>{
    9143 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    9142 => { pos => '040', def => 'an..35', },
}},
'C942' => { label => 'MEMBERSHIP CATEGORY', desc => 'Identification and/or description of a membership category for a member of a scheme or group.', parts =>{
    7451 => { pos => '010', def => 'an..4' , mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7450 => { pos => '040', def => 'an..35', },
}},
'C944' => { label => 'MEMBERSHIP STATUS', desc => 'Code and/or description of membership status.', parts =>{
    7453 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    7452 => { pos => '040', def => 'an..35', },
}},
'C945' => { label => 'MEMBERSHIP LEVEL', desc => 'Identification of a membership level.', parts =>{
    7455 => { pos => '010', def => 'an..3' , mandatory => 1, },
    7457 => { pos => '020', def => 'an..9' , },
    1131 => { pos => '030', def => 'an..17', },
    3055 => { pos => '040', def => 'an..3' , },
    7456 => { pos => '050', def => 'an..35', },
}},
'C948' => { label => 'EMPLOYMENT CATEGORY', desc => 'Code and/or description of an employment category.', parts =>{
    9005 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    9004 => { pos => '040', def => 'an..35', },
}},
'C950' => { label => 'QUALIFICATION CLASSIFICATION', desc => 'Qualification classification description and/or code. This specifies the trade, skill, professional or similar qualification category.', parts =>{
    9007 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    9006 => { pos => '040', def => 'an..35', },
    9006 => { pos => '050', def => 'an..35', },
}},
'C951' => { label => 'OCCUPATION', desc => 'Description of an occupation.', parts =>{
    9009 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    9008 => { pos => '040', def => 'an..35', },
    9008 => { pos => '050', def => 'an..35', },
}},
'C953' => { label => 'CONTRIBUTION TYPE', desc => 'Identification of the type of a contribution to a scheme or group.', parts =>{
    5049 => { pos => '010', def => 'an..3' , mandatory => 1, },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    5048 => { pos => '040', def => 'an..35', },
}},
'C955' => { label => 'ATTRIBUTE TYPE', desc => 'Identification of the type of attribute.', parts =>{
    9021 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    9020 => { pos => '040', def => 'an..70', },
}},
'C956' => { label => 'ATTRIBUTE DETAIL', desc => 'Identification of the attribute related to an entity.', parts =>{
    9019 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    9018 => { pos => '040', def => 'an..256', },
}},
'C960' => { label => 'REASON FOR CHANGE', desc => 'Code and/or description of the reason for a change.', parts =>{
    4295 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    4294 => { pos => '040', def => 'an..35', },
}},
'C961' => { label => 'FORMULA COMPLEXITY', desc => 'Identification of the complexity of a formula.', parts =>{
    9505 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
}},
'C970' => { label => 'CLAUSE NAME', desc => 'Identification of a clause in coded or clear form.', parts =>{
    4069 => { pos => '010', def => 'an..17', },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    4068 => { pos => '040', def => 'an..70', },
}},
'C971' => { label => 'PROVISO TYPE', desc => 'Specification of the proviso type in coded or clear form.', parts =>{
    4073 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    4072 => { pos => '040', def => 'an..35', },
}},
'C972' => { label => 'PROVISO CALCULATION', desc => 'Specification of the proviso calculation in coded or clear form.', parts =>{
    4075 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    4074 => { pos => '040', def => 'an..35', },
}},
'C973' => { label => 'APPLICABILITY TYPE', desc => 'Specification of the applicability type in coded or clear form.', parts =>{
    9049 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    9048 => { pos => '040', def => 'an..35', },
}},
'C974' => { label => 'BASIS TYPE', desc => 'Specification of the basis in coded or clear form.', parts =>{
    9047 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    9046 => { pos => '040', def => 'an..35', },
}},
'C977' => { label => 'PERIOD DETAIL', desc => 'Specification of the period detail in coded or clear form.', parts =>{
    2119 => { pos => '010', def => 'an..3' , },
    1131 => { pos => '020', def => 'an..17', },
    3055 => { pos => '030', def => 'an..3' , },
    2118 => { pos => '040', def => 'an..35', },
}},
};

sub codemap {
    # my $self = shift;
    return $guts;
}

sub chunk {
    my ($class, $key) = @_;
    my $chunk = $guts->{$key};
    if (! $chunk) {
         $debug and carp __PACKAGE__ . " : Composite key '$key' unrecognized";
         return;
    }
    return $chunk;
}

sub spec_parts {
    my ($class, $key) = @_;
    if (! $key) {
        carp __PACKAGE__ . "->spec_parts() called without required argument for ccode key";
        return;
    }
    my $chunk = $class->chunk($key);
    return $chunk->{parts};
}

sub parts {
    my $self = shift;
    unless (ref $self) {    # if it is just Business::EDI::Composite->parts
        return $self->spec_parts(@_);   # just do a lookup
    }
    my $chunk = $self->chunk(@_ ? shift : $self->ccode) or return;
    return $chunk->{parts};
}
sub code {
    my $self = shift;
    @_ and $self->{ccode} = shift;
    return $self->{ccode};
}
sub ccode {
    my $self = shift;
    @_ and $self->{ccode} = shift;
    return $self->{ccode};
}
sub label {
    my $self = shift;
    @_ and $self->{label} = shift;
    return $self->{label};
}
sub desc {
    my $self = shift;
    @_ and $self->{desc} = shift;
    return $self->{desc};
}
sub value {
    my $self = shift;
    @_ and $self->{value} = shift;
    return $self->{value};
}

=head2 ->new($body)

$body is a hashref like:

  { 'C002' => {
       '1001' => '231'
    }
  }

The top level should have only one composite "Cxxx" key.

=cut

sub new {
    my $class = shift;
    my $body  = shift;
    unless ($body) {
        carp __PACKAGE__ . " : empty argument to new()";
        return;
    }
    unless (ref($body) eq 'HASH') {
        carp __PACKAGE__ . " : argument to new() must be a HASHref, not '" . ref($body) . "'";
        return;
    }

    my (@keys, $key, $chunk, $repeat);
    @keys = keys %$body;
    unless (scalar @keys == 1) {
        carp __PACKAGE__ . " : HASHref arg. to new() must have (only) 1 top level key (e.q. C977).  We got " . scalar(@keys);
        return;
    }
    $key = $keys[0];
    unless ($chunk = $guts->{$key}) {   # assignment, not comparison
        carp __PACKAGE__ . " : Composite key '$key' unrecognized";
        return;
    }
    my $value = $body->{$key};
    if (ref($value) eq 'ARRAY') {
        if (scalar @$value == 1) {
            $debug and carp "Flattening repeating $key array with only 1 element";
            $value = $value->[0];
        } else { 
            carp "Repeating value actually repeats (" . scalar(@$value) . " times).  Not implemented"; # TODO
            return;
        }
        $repeat = -1;
    }
    my $self = $class->SUPER::unblessed($value, [(keys %{$chunk->{parts}})], $debug);     # send the "parts" hashref
    $self->{ccode} = $key;             # the Cxxx key
    $self->{code}  = $key;             # the Cxxx key
#   $self->{value} = $value;           # the hashref value associated with the key -- not a value
    $self->{label} = $chunk->{label};  # label from spec
    $self->{desc}  = $chunk->{desc};   # desc from spec
    $self->{repeat}= $repeat if $repeat;
    return bless $self, $class;
}

1;
