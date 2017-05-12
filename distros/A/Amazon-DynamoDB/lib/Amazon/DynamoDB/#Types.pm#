package Amazon::DynamoDB::Types;

use strict;
use warnings;
use Type::Library
    "-base",
    "-declare" => qw( 
                      TableNameType
                      AttributeDefinitionsType
                      SelectType
                      ReturnValuesType
                      ReturnItemCollectionMetricsType
                      ReturnConsumedCapacityType
                      ConditionalOperatorType
                      StringBooleanType
                      ComparisonOperatorType
                      AttributeNameType
                      AttributeValueType
                      KeySchemaType
                      GlobalSecondaryIndexType
                      LocalSecondaryIndexType
                      TableStatusType
                      ExpectedType
                      AttributeUpdatesType
                      ItemType
                      KeyType
                      BatchWritePutItemType
                      BatchWriteDeleteItemType
                      BatchWriteRequestItemsType
                      BatchGetItemsType
                      KeyConditionsType
                      QueryFilterType
                      ScanFilterType
                      ExpectedValueType
                      ExpressionAttributeValuesType
                      ExpressionAttributeNamesType
                      AttributesToGetType);
              
use Type::Utils -all;
use Types::Standard -types;


declare AttributeNameType, as Str, where { length($_) >= 1 && length($_) <= 255 };

declare "TableNameType", as StrMatch[qr/^[a-zA-Z0-9_\-\.]{3,255}$/];
coerce TableNameType, from Str, via {
    TableNameType->new($_);
};


declare "AttributeDefinitionsType", as Map[AttributeNameType, StrMatch[qr/^(S|N|B)$/]];
coerce AttributeDefinitionsType, from HashRef, via {
    AttributeDefinitionsType->new($_);
};


declare ComparisonOperatorType, as StrMatch[qr/^(EQ|NE|LE|LT|GE|GT|NOT_NULL|NULL|CONTAINS|NOT_CONTAINS|BEGINS_WITH|IN|BETWEEN)$/];
coerce ComparisonOperatorType, from Str, via { ComparisonOperatorType->new($_); };

declare SelectType, as StrMatch[qr/^(ALL_ATTRIBUTES|ALL_PROJECTED_ATTRIBUTES|SPECIFIC_ATTRIBUTES|COUNT)$/];
coerce SelectType, from Str, via { SelectType->new($_); };

declare ReturnValuesType, as StrMatch[qr/^(NONE|ALL_OLD|UPDATED_OLD|ALL_NEW|UPDATED_NEW)$/];
coerce ReturnValuesType, from Str, via { ReturnValuesType->new($_); };

declare ReturnItemCollectionMetricsType, as StrMatch[qr/^(NONE|SIZE)$/];
coerce ReturnItemCollectionMetricsType, from Str, via { ReturnItemCollectionMetricsType->new($_); };

declare ReturnConsumedCapacityType, as StrMatch[qr/^(INDEXES|TOTAL|NONE)$/];
coerce ReturnConsumedCapacityType, from Str, via { ReturnConsumedCapacityType->new($_); };


declare ConditionalOperatorType, as StrMatch[qr/^(AND|OR)$/];    
coerce ConditionalOperatorType, from Str, via { ConditionalOperatorType->new($_); };

declare StringBooleanType, as StrMatch[qr/^(true|false)$/];
coerce StringBooleanType, from Str, via { StringBooleanType->new($_); };

declare AttributeValueType, as Defined, where {  
    my $v = shift @_;
    my $ref_type = ref($v);
    if ($ref_type ne '') {
        if ($ref_type eq 'SCALAR') {
            return defined($$v);
        } elsif ($ref_type eq 'ARRAY') {
            return scalar(@$v) > 0;
        } 
    } else {
        return $v =~ /\S/;
    }
    return 0;
};

declare AttributesToGetType, as ArrayRef[AttributeNameType], where { scalar(@$_) >= 1 };

    
declare KeySchemaType, as ArrayRef[AttributeNameType], where { scalar(@$_) <= 2 && scalar(@$_) > 0 };

declare GlobalSecondaryIndexType, as Dict[IndexName => TableNameType,
                                            ProvisionedThroughput => Optional[Dict[ReadCapacityUnits => Optional[Int],
                                                                                   WriteCapacityUnits => Optional[Int]
                                                                               ]
                                                                          ],
                                            KeySchema => KeySchemaType,
                                            Projection => Optional[Dict[ProjectionType => StrMatch[qr/^(KEYS_ONLY|INCLUDE|ALL)$/],
                                                                        NonKeyAttributes => Optional[ArrayRef[AttributeNameType]]]],
                                       ];

coerce GlobalSecondaryIndexType, from HashRef, via {
    GlobalSecondaryIndexType->new($_);
};

declare LocalSecondaryIndexType, as Dict[IndexName => TableNameType,
                                           KeySchema => KeySchemaType,
                                           Projection => Optional[Dict[ProjectionType => StrMatch[qr/^(KEYS_ONLY|INCLUDE|ALL)$/],
                                                                       NonKeyAttributes => Optional[ArrayRef[AttributeNameType]]]]
                                       ];
coerce LocalSecondaryIndexType, from HashRef, via {
    LocalSecondaryIndexType->new($_);
};

declare TableStatusType, as StrMatch[qr/^(CREATING|UPDATING|DELETING|ACTIVE)$/];
coerce TableStatusType, from Str, via { TableStatusType->new($_) };

declare ExpectedValueType, as Dict[AttributeValueList => Optional[AttributeValueType],
                                   ComparisonOperator => Optional[ComparisonOperatorType],
                                   Exists => Optional[StringBooleanType],
                                   Value => Optional[AttributeValueType],
                               ], where { scalar(keys %$_) > 0 && 
                                              # don't allow both forms of expected/comparision operator
                                              # to be used at the same time.
                                              ((exists($_->{AttributeValueList}) || exists($_->{ComparisonOperator}))
                                               xor
                                              (exists($_->{Exists}) || exists($_->{Value})))
                                          };

declare ExpectedType, as Map[AttributeNameType, ExpectedValueType];



coerce ExpectedType, from HashRef, via { ExpectedType->new($_) };


declare AttributeUpdatesType, as Map[AttributeNameType, Dict[Action => StrMatch[qr/^(PUT|DELETE|ADD)$/],
                                                             Value => Optional[AttributeValueType]]];
coerce AttributeUpdatesType, from HashRef, via { AttributeUpdatesType->new($_); };

declare ItemType, as Map[AttributeNameType, AttributeValueType];
declare KeyType, as Map[AttributeNameType, AttributeValueType], where { scalar(keys %$_) > 0 && scalar(keys %$_) < 3 };

declare BatchWritePutItemType, as Dict[PutRequest => Dict[Item => ItemType]];
declare BatchWriteDeleteItemType, as Dict[DeleteRequest => Dict[Key => KeyType]];
declare BatchWriteRequestItemsType, as Map[TableNameType, ArrayRef[BatchWritePutItemType|BatchWriteDeleteItemType]], where { scalar(keys %$_) > 0 };

declare BatchGetItemsType, as Map[TableNameType, Dict[AttributesToGet => Optional[AttributesToGetType],
                                                      ConsistentRead => Optional[StringBooleanType],
                                                      Keys => ArrayRef[KeyType]]
                              ], where { scalar(keys %$_) > 0 };


declare KeyConditionsType, as Map[AttributeNameType, Dict[AttributeValueList => AttributeValueType,
                                                            ComparisonOperator => StrMatch[qr/^(EQ|LE|LT|GE|GT|BEGINS_WITH|BETWEEN)$/]
                                                        ]];


declare QueryFilterType, as Map[AttributeNameType, Dict[AttributeValueList => Optional[AttributeValueType],
                                                        ComparisonOperator => ComparisonOperatorType
                                                      ]];


declare ScanFilterType, as Map[AttributeNameType, Dict[AttributeValueList => Optional[AttributeValueType],
                                                       ComparisonOperator => ComparisonOperatorType
                                                     ]];

declare ExpressionAttributeValuesType, as Map[StrMatch[qr/^:[a-zA-Z][a-z0-9A-Z_]*$/], AttributeValueType];
coerce ExpressionAttributeValuesType, from HashRef, via { ExpressionAttributeValuesType->new($_) };

declare ExpressionAttributeNamesType, as Map[StrMatch[qr/^\#[a-zA-Z][a-z0-9A-Z_]*$/], Str];
coerce ExpressionAttributeNamesType, from HashRef, via { ExpressionAttributeNamesType->new($_) };


1;
