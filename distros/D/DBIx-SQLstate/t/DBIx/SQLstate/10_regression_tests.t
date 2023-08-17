use Test::More;

use DBIx::SQLstate qw/sqlstate_codes/;



=head1 DESCRIPTION

These tests are here to check for specific SQLstate codes which may have some
interesting capitalisation issues, or punctuation characters etc.

=cut



$DBIx::SQLstate::CONST_PREFIX = undef;

my %test_cases = (
    
    '01004' => {
        title => 'String data, right truncation',
        token => 'StringDataRightTruncation',
        const => 'STRING_DATA_RIGHT_TRUNCATION',
        notes => 'Check that comma-space is mapped to a single underscore',
        to_do => 'this is okay now',
    },
    
    '01011' => {
        title => 'SQL-Java path too long for information schema',
        token => 'SQLjavaPathTooLongForInformationSchema',
    },
    
    '07000' => {
        title => 'Dynamic SQL error',
        token => 'DynamicSQLerror',
        notes => 'Correct capitalization of: SQL',
    },
    
    '0N000' => {
        title => 'SQL/XML mapping error',
        token => 'SQLXMLmappingError',
        const => 'SQL_XML_MAPPING_ERROR',
    },
    
    '2200U' => {
        title => 'Not an XQuery document node',
        token => 'NotXQueryDocumentNode',
        const => 'NOT_XQUERY_DOCUMENT_NODE',
        notes => 'Correct capitalization of: XQuery',
    },
    
    '39004' => {
        title => 'null value not allowed',
        token => 'NULLvalueNotAllowed',
        notes => 'Correct capitalization of: NULL',
    },
    
    'HY000' => {
        title => 'CLI-specific condition',
        token => 'CLIspecificCondition',
        notes => 'Correct capitalization of: CLI',
    },

    'HY099' => {
        title => 'nullable type out of range',
        token => 'NullableTypeOutOfRange',
        notes => 'Not all null occurances are a NULL',
    },
    
    'HZ???' => {
        title => 'Reserved for ISO9579 (RDA)',
        token => 'ReservedForISO9579RDA',
        const => 'RESERVED_FOR_ISO9579_RDA',
        to_do => 'Need to fix ISO, parrenthesis, and RDA',
    }
    
);



foreach (sort keys %test_cases) {
    
    subtest "SQL-state $_: ${test_cases{$_}{title}}" => sub {
        
        note $test_cases{$_}{notes}
            if $test_cases{$_}{notes};
        
        ok( +{ sqlstate_codes() }->{$_},
            "SQL-state code exists"
        );
        
        TODO: {
            
            local $TODO = $test_cases{$_}{to_do};
                
            is( DBIx::SQLstate->token($_),
                $test_cases{$_}{token},
                "... and got the right token"
            ) if exists $test_cases{$_}{token};
            
            is( DBIx::SQLstate->const($_),
                $test_cases{$_}{const},
                "... and got the right constant"
            ) if exists $test_cases{$_}{const};
            
        }
    
    }
}


done_testing;

__END__
