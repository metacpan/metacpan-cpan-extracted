package Amazon::DynamoDB::20120810;
$Amazon::DynamoDB::20120810::VERSION = '0.35';
use strict;
use warnings;


use Future;
use Future::Utils qw(repeat try_repeat);
use POSIX qw(strftime);
use JSON::MaybeXS qw(decode_json encode_json);
use MIME::Base64;
use List::Util;
use List::MoreUtils;
use B qw(svref_2object);
use HTTP::Request;
use Kavorka;
use Amazon::DynamoDB::Types;
use Type::Registry;
use VM::EC2::Security::CredentialCache;
use AWS::Signature4;
   
BEGIN {
    my $reg = "Type::Registry"->for_me; 
    $reg->add_types(-Standard);
    $reg->add_types("Amazon::DynamoDB::Types");
};



sub new {
    my $class = shift;
    bless { @_ }, $class
}

sub implementation { shift->{implementation} }
sub host { shift->{host} }
sub port { shift->{port} }
sub ssl { shift->{ssl} }
sub algorithm { 'AWS4-HMAC-SHA256' }
sub scope { shift->{scope} }
sub access_key { shift->{access_key} }
sub secret_key { shift->{secret_key} }
sub debug_failures { shift->{debug} }

sub max_retries { shift->{max_retries} }





method create_table(TableNameType :$TableName!,
                    Int :$ReadCapacityUnits = 2, 
                    Int :$WriteCapacityUnits = 2,
                    AttributeDefinitionsType :$AttributeDefinitions,
                    KeySchemaType :$KeySchema!,
                    ArrayRef[GlobalSecondaryIndexType] :$GlobalSecondaryIndexes where { scalar(@$_) <= 5 },
                    ArrayRef[LocalSecondaryIndexType] :$LocalSecondaryIndexes
                ) {
    my %payload = (
        TableName => $TableName,
        ProvisionedThroughput => {
            ReadCapacityUnits => int($ReadCapacityUnits),
            WriteCapacityUnits => int($WriteCapacityUnits),
        }
    );

    if (defined($AttributeDefinitions)) {
        foreach my $field_name (keys %$AttributeDefinitions) {
            my $type = $AttributeDefinitions->{$field_name};

            push @{$payload{AttributeDefinitions}}, {
                AttributeName => $field_name,
                AttributeType => $type // 'S',
            }
        }
    }

    $payload{KeySchema} = _create_key_schema($KeySchema, $AttributeDefinitions);

    foreach my $index_record (['GlobalSecondaryIndexes', $GlobalSecondaryIndexes], 
                              ['LocalSecondaryIndexes', $LocalSecondaryIndexes]) {
        my $index_type = $index_record->[0];
        my $index = $index_record->[1];
        
        if (defined($index)) {
            foreach my $i (@$index) {
                my $r = {
                    IndexName => $i->{IndexName},
                    (($index_type eq 'GlobalSecondaryIndexes') ? 
                         (ProvisionedThroughput => {
                             ReadCapacityUnits => int($i->{ProvisionedThroughput}->{ReadCapacityUnits} // 1),
                             WriteCapacityUnits => int($i->{ProvisionedThroughput}->{WriteCapacityUnits} // 1),
                         }) : ()),
                    KeySchema => _create_key_schema($i->{KeySchema}, $AttributeDefinitions),
                };

                my $type = $i->{Projection}->{ProjectionType};
                $r->{Projection}->{ProjectionType} = $type;
                
                if (defined($i->{Projection}->{NonKeyAttributes})) {
                    my $attrs = $i->{Projection}->{NonKeyAttributes};
                    # Can't validate these attribute names since they aren't part of the key.
                    $r->{Projection}->{NonKeyAttributes} = $attrs;
                }
                push @{$payload{$index_type}}, $r;
            }
        }
    }

    my $req = $self->make_request(
        target => 'CreateTable',
        payload => \%payload,
    );
    $self->_process_request($req)
}


method describe_table(TableNameType :$TableName!) {
    my $req = $self->make_request(
        target => 'DescribeTable',
        payload => _make_payload({
            TableName => $TableName
        }));
    $self->_process_request($req,
                            sub { 
                                my $content = shift; 
                                decode_json($content)->{Table};
                            });
}


method delete_table(TableNameType :$TableName!) {
    my $req = $self->make_request(
        target => 'DeleteTable',
        payload => _make_payload({ TableName => $TableName }));
    $self->_process_request($req,
                            sub {
                                my $content = shift;
                                decode_json($content)->{TableDescription}
                            });
}


method wait_for_table_status(TableNameType :$TableName!,
                             Int :$WaitInterval = 2,
                             TableStatusType :$DesiredStatus = "ACTIVE") {
    repeat {
        my $retry = shift;
        
        $self->{implementation}->delay($retry ? $WaitInterval : 0)
            ->then(sub {
                       $self->describe_table(TableName => $TableName) 
                   });
    } until => sub {
        my $f = shift;
        my $status = $f->get->{TableStatus};
        $status eq $DesiredStatus
    };
}


method each_table(CodeRef $code,
                  TableNameType :$ExclusiveStartTableName,
                  Int :$Limit where { $_ >= 0 && $_ <= 100}
              ) {
    my $finished = 0;
    try_repeat {
        my $req = $self->make_request(
            target => 'ListTables',
            payload => _make_payload({ 
                ExclusiveStartTableName => $ExclusiveStartTableName,
                Limit => $Limit
            }));
        $self->_process_request($req,
                                sub {
                                    my $result = shift;
                                    my $data = decode_json($result);
                                    for my $tbl (@{$data->{TableNames}}) {
                                        $code->($tbl);
                                    }
                                    $ExclusiveStartTableName = $data->{LastEvaluatedTableName};
                                    if (!defined($ExclusiveStartTableName)) {
                                        $finished = 1 
                                    }
                                });
    } while => sub { !$finished };
}


method put_item (ConditionalOperatorType :$ConditionalOperator,
                 Str :$ConditionExpression,
                 ItemType :$Item!,
                 ExpectedType :$Expected,
                 ExpressionAttributeValuesType :$ExpressionAttributeValues,
                 ReturnConsumedCapacityType :$ReturnConsumedCapacity,
                 ReturnItemCollectionMetricsType :$ReturnItemCollectionMetrics,
                 ReturnValuesType :$ReturnValues,
                 TableNameType :$TableName!) {
    my $req = $self->make_request(
        target => 'PutItem',
        payload => _make_payload({
            'ConditionalOperator' => $ConditionalOperator,
            'Expected' => $Expected,
            'ConditionExpression' => $ConditionExpression,
            'ExpressionAttributeValues' => $ExpressionAttributeValues,
            'Item' => $Item,
            'ReturnConsumedCapacity' => $ReturnConsumedCapacity,
            'ReturnItemCollectionMetrics' => $ReturnItemCollectionMetrics,
            'ReturnValues' => $ReturnValues,
            'TableName' => $TableName
        }));
                             
    $self->_process_request($req, \&_decode_single_item_change_response);
}



method update_item (AttributeUpdatesType :$AttributeUpdates,
                    Str :$ConditionExpression,
                    ConditionalOperatorType :$ConditionalOperator,
                    ExpectedType :$Expected,
                    KeyType :$Key!,
                    ReturnConsumedCapacityType :$ReturnConsumedCapacity,
                    ReturnItemCollectionMetricsType :$ReturnItemCollectionMetrics,
                    ReturnValuesType :$ReturnValues,
                    TableNameType :$TableName!,
                    ExpressionAttributeValuesType :$ExpressionAttributeValues,
                    ExpressionAttributeNamesType :$ExpressionAttributeNames,
                    Str :$UpdateExpression,
                ) {
    (defined($AttributeUpdates) xor defined($UpdateExpression)) || die("Either AttributeUpdates or UpdateExpression is required");
    
    my $req = $self->make_request(
        target => 'UpdateItem',
        payload => _make_payload({
                                 'AttributeUpdates' => $AttributeUpdates,
                                 'ConditionalOperator' => $ConditionalOperator,
                                 'ConditionExpression' => $ConditionExpression,
                                 'Expected' => $Expected,
                                 'ExpressionAttributeNames' => $ExpressionAttributeNames,
                                 'ExpressionAttributeValues' => $ExpressionAttributeValues,
                                 'Key' => $Key,
                                 'ReturnConsumedCapacity' => $ReturnConsumedCapacity,
                                 'ReturnItemCollectionMetrics' => $ReturnItemCollectionMetrics,
                                 'ReturnValues' => $ReturnValues,
                                 'TableName' => $TableName,
                                 'UpdateExpression' => $UpdateExpression,
                                 }));
    $self->_process_request($req, \&_decode_single_item_change_response);
}




method delete_item(ConditionalOperatorType :$ConditionalOperator,
                   ExpectedType :$Expected,
                   KeyType :$Key!,
                   ReturnConsumedCapacityType :$ReturnConsumedCapacity,
                   ReturnItemCollectionMetricsType :$ReturnItemCollectionMetrics,
                   ReturnValuesType :$ReturnValues,
                   TableNameType :$TableName!) {
    my $req = $self->make_request(
        target => 'DeleteItem',
        payload => _make_payload({
                                 'ConditionalOperator' => $ConditionalOperator,
                                 'Expected' => $Expected,
                                 'Key' => $Key,
                                 'ReturnConsumedCapacity' => $ReturnConsumedCapacity,
                                 'ReturnItemCollectionMetrics' => $ReturnItemCollectionMetrics,
                                 'ReturnValues' => $ReturnValues,
                                 'TableName' => $TableName
                                 }));
            
    $self->_process_request($req, \&_decode_single_item_change_response);
}




method get_item(CodeRef $code,
                AttributesToGetType :$AttributesToGet,
                StringBooleanType :$ConsistentRead,
                KeyType :$Key!,
                ReturnConsumedCapacityType :$ReturnConsumedCapacity,
                TableNameType :$TableName!) {
    my $req = $self->make_request(
        target => 'GetItem',
        payload => _make_payload({
                                 'AttributesToGet' => $AttributesToGet,
                                 'ConsistentRead' => $ConsistentRead,
                                 'Key' => $Key,
                                 'ReturnConsumedCapacity' => $ReturnConsumedCapacity,
                                 'TableName' => $TableName
                            }));
    
    $self->_process_request(
        $req, 
        sub {
            my $result = shift;
            my $data = decode_json($result);
            $code->(_decode_item_attributes($data->{Item}));
        });
}




method batch_write_item(BatchWriteRequestItemsType :$RequestItems! where { scalar(keys %$_) > 0 },
                        ReturnConsumedCapacityType :$ReturnConsumedCapacity,
                        ReturnItemCollectionMetricsType :$ReturnItemCollectionMetrics,
                    ) {
    my @all_requests;

    foreach my $table_name (keys %$RequestItems) {
        # Item.
        my $table_items = $RequestItems->{$table_name};
            
        my $seen_type;
        foreach my $item (@$table_items) {
            my $r;
            foreach my $t (['DeleteRequest', 'Key'], ['PutRequest', 'Item']) {
                if (defined($item->{$t->[0]})) {
                    my $key = $item->{$t->[0]}->{$t->[1]};
                    foreach my $k (keys %$key) {
                        # Don't bother encoding undefined values, same behavior as put_item
                        if (defined($key->{$k})) {
                            $r->{$t->[0]}->{$t->[1]}->{$k} = { _encode_type_and_value($key->{$k}) };
                        }
                    }
                }
            }
            if (defined($r)) {
                push @all_requests, [$table_name, $r];
            }
        }
    }

    try_repeat {
        my %payload = (
            ReturnConsumedCapacity => $ReturnConsumedCapacity,
            ReturnItemCollectionMetrics => $ReturnItemCollectionMetrics
        );

        #            print "Pending requests: " . scalar(@all_requests) . "\n";
        my @records = splice @all_requests, 0, List::Util::min(25, scalar(@all_requests));
            

        foreach my $record (@records) {
            push @{$payload{RequestItems}->{$record->[0]}}, $record->[1];
        }
            

        my $req = $self->make_request(
            target => 'BatchWriteItem',
            payload => \%payload,
        );

        $self->_process_request(
            $req,
            sub {
                my $result = shift;
                my $data = decode_json($result);
                    
                if (defined($data->{UnprocessedItems})) {
                    foreach my $table_name (keys %{$data->{UnprocessedItems}}) {
                        push @all_requests, map { [$table_name, $_] } @{$data->{UnprocessedItems}->{$table_name}};
                    }
                }
                return $data;
            })->on_fail(sub { 
                            @all_requests = ();
                        });
    } until => sub { scalar(@all_requests) == 0 };
}





method batch_get_item(CodeRef $code,
                      BatchGetItemsType :$RequestItems!,
                      ReturnConsumedCapacityType :$ReturnConsumedCapacity,
                      Int :$ResultLimit where { !defined($_) || $_ > 0 }
                  ) {
    my @all_requests;
    my $table_flags = {};

    foreach my $table_name (keys %$RequestItems) {
        my $table_details = $RequestItems->{$table_name};

        # Store these flags for later.
        map { 
            if (defined($table_details->{$_})) {
                $table_flags->{$_} = $table_details->{$_};
            }
        } ('ConsistentRead', 'AttributesToGet');

        foreach my $item (@{$table_details->{Keys}}) {
            my $r = {};
            foreach my $key_field (keys %$item) {
                $r->{$key_field} = { _encode_type_and_value($item->{$key_field}) };
            }
            push @all_requests, [$table_name, $r];
        }
    }

    my $records_seen =0;
    try_repeat {

        my %payload = (
            ReturnConsumedCapacity => $ReturnConsumedCapacity
        );

        # Only try 100 requests at one time.
        my @records = splice @all_requests, 0, List::Util::min(100, scalar(@all_requests));


        foreach my $record (@records) {
            push @{$payload{RequestItems}->{$record->[0]}->{Keys}}, $record->[1];
        }
            
        foreach my $seen_table_name (grep { defined($table_flags->{$_}) } List::MoreUtils::uniq(map { $_->[0] } @records)) {
            $payload{RequestItems}->{$seen_table_name} = {
                %{$table_flags->{$seen_table_name}},
                Keys => $payload{RequestItems}->{$seen_table_name}->{Keys}
            };
        }

        my $req = $self->make_request(
            target => 'BatchGetItem',
            payload => \%payload,
        );

        $self->_process_request(
            $req,
            sub {
                my $result = shift;
                my $data = decode_json($result);
                foreach my $table_name (keys %{$data->{Responses}}) {
                    foreach my $item (@{$data->{Responses}->{$table_name}}) {
                        $code->($table_name, _decode_item_attributes($item));
                        $records_seen += 1;
                        if (defined($ResultLimit) &&$records_seen >= $ResultLimit) {
                            @all_requests = ();
                            return $data;
                        }
                    }
                }
                    
                if (defined($data->{UnprocessedKeys})) {
                    foreach my $table_name (keys %{$data->{UnprocessedKeys}}) {
                        push @all_requests, map { [$table_name, $_] } @{$data->{UnprocessedKeys}->{$table_name}->{Keys}};
                    }
                }
                return $data;
            })->on_fail(sub { 
                            @all_requests = ();
                        });
    } until => sub { scalar(@all_requests) == 0 };
}


method query (CodeRef $code,
              AttributesToGetType :$AttributesToGet,
              StringBooleanType :$ConsistentRead,
              ConditionalOperatorType :$ConditionalOperator,
              KeyType :$ExclusiveStartKey,
              TableNameType :$IndexName,
              KeyConditionsType :$KeyConditions!,
              Int :$Limit where { $_ >= 0 },
              QueryFilterType :$QueryFilter,
              ReturnConsumedCapacityType :$ReturnConsumedCapacity,
              StringBooleanType :$ScanIndexForward,
              SelectType :$Select,
              TableNameType :$TableName!,
              Str :$FilterExpression,
              ExpressionAttributeValuesType :$ExpressionAttributeValues,
              ExpressionAttributeNamesType :$ExpressionAttributeNames,
          ) {

    my $payload = _make_payload({
                                'AttributesToGet' => $AttributesToGet,
                                'ConsistentRead' => $ConsistentRead,
                                'ConditionalOperator' => $ConditionalOperator,
                                'ExclusiveStartKey' => $ExclusiveStartKey,
                                'ExpressionAttributeNames' => $ExpressionAttributeNames,
                                'ExpressionAttributeValues' => $ExpressionAttributeValues,
                                'FilterExpression' => $FilterExpression,
                                'IndexName' => $IndexName,
                                'QueryFilter' => $QueryFilter,
                                'ReturnConsumedCapacity' => $ReturnConsumedCapacity,
                                'ScanIndexForward' => $ScanIndexForward,
                                'Select' => $Select,
                                'TableName' => $TableName
                            });
    

    foreach my $key_name (keys %$KeyConditions) {
        my $key_details = $KeyConditions->{$key_name};
        $payload->{KeyConditions}->{$key_name} = {
            AttributeValueList => _encode_attribute_value_list($key_details->{AttributeValueList}, $key_details->{ComparisonOperator}),
            ComparisonOperator => $key_details->{ComparisonOperator}
        };
    }

    $self->_scan_or_query_process('Query', $payload, $code, { ResultLimit => $Limit});
}





method scan (CodeRef $code,
             AttributesToGetType :$AttributesToGet,
             KeyType :$ExclusiveStartKey,
             Int :$Limit where { $_ >= 0},
             ReturnConsumedCapacityType :$ReturnConsumedCapacity,
             ScanFilterType :$ScanFilter,
             Int :$Segment where { $_ >= 0 },
             SelectType :$Select,
             TableNameType :$TableName!,
             Int :$TotalSegments where { $_ >= 1 && $_ <= 1000000 },
             Str :$FilterExpression,
             ExpressionAttributeValuesType :$ExpressionAttributeValues,
             ExpressionAttributeNamesType :$ExpressionAttributeNames,
         ) {
    my $payload = _make_payload({
                                'AttributesToGet' => $AttributesToGet,
                                'ExclusiveStartKey' => $ExclusiveStartKey,
                                'ExpressionAttributeValues' => $ExpressionAttributeValues,
                                'ExpressionAttributeNames' => $ExpressionAttributeNames,
                                'FilterExpression' => $FilterExpression,
                                'ReturnConsumedCapacity' => $ReturnConsumedCapacity,
                                'ScanFilter' => $ScanFilter,
                                'Segment' => $Segment,
                                'Select' => $Select,
                                'TableName' => $TableName,
                                'TotalSegments' => $TotalSegments
                            });

    $self->_scan_or_query_process('Scan', $payload, $code, { ResultLimit => $Limit});
}


method make_request(Str :$target,
                    HashRef :$payload,
                ) {
    my $api_version = '20120810';
    my $host = $self->host;
    my $req = HTTP::Request->new(
        POST => (($self->ssl) ? 'https' : 'http') . '://' . $self->host . ($self->port ? (':' . $self->port) : '') . '/'
    );
    $req->header( host => $host );
    # Amazon requires ISO-8601 basic format
    my $now = time;
    my $http_date = strftime('%Y%m%dT%H%M%SZ', gmtime($now));
    my $date = strftime('%Y%m%d', gmtime($now));

    $req->protocol('HTTP/1.1');
    $req->header( 'Date' => $http_date );
    $req->header( 'x-amz-target', 'DynamoDB_'. $api_version. '.'. $target );
    $req->header( 'content-type' => 'application/x-amz-json-1.0' );
    $payload = encode_json($payload);
    $req->content($payload);
    $req->header( 'Content-Length' => length($payload));
    
    if ($self->{use_iam_role}) {
        my $creds = VM::EC2::Security::CredentialCache->get();
        defined($creds) || die("Unable to retrieve IAM role credentials");
        $self->{access_key} = $creds->accessKeyId;
        $self->{secret_key} = $creds->secretAccessKey;
        $req->header('x-amz-security-token' => $creds->sessionToken);
    }        

    my $signer = AWS::Signature4->new(-access_key => $self->access_key,
                                      -secret_key => $self->secret_key);
    
    $signer->sign($req);
    return $req;
}

method _request(HTTP::Request $req) {
    $self->implementation->request($req);
}


# Since scan and query have the same type of responses share the processing.
method _scan_or_query_process (Str $target,
                               HashRef $payload,
                               CodeRef $code,
                               HashRef $args) {
    my $finished = 0;
    my $records_seen = 0;
    my $repeat = try_repeat {
        
        # Since we're may be making more than one request in this repeat loop
        # decrease our limit of results to scan in each call by the number 
        # of records remaining that the overall request wanted ot pull.
        if (defined($args->{ResultLimit})) {
            $payload->{Limit} = $args->{ResultLimit} - $records_seen;
        }

        my $req = $self->make_request(
            target => $target,
            payload => $payload,
        );
        
        $self->_process_request(
            $req,
            sub {
                my $result = shift;
                my $data = decode_json($result);
                
                for my $entry (@{$data->{Items}}) {
                    $code->(_decode_item_attributes($entry));
                }

                $records_seen += scalar(@{$data->{Items}});
                if ((defined($args->{ResultLimit}) && $records_seen >= $args->{ResultLimit})) {
                    $finished = 1;
                } 

                if (!defined($data->{LastEvaluatedKey})) {
                    $finished = 1;
                } else {
                    if (!$finished) {
                        $payload->{ExclusiveStartKey} = $data->{LastEvaluatedKey};                    
                    }
                }
                
                if (defined($data->{LastEvaluatedKey}) && $finished) {
                    $data->{LastEvaluatedKey} = _decode_item_attributes($data->{LastEvaluatedKey});
                }


                return $data;
            })
            ->on_fail(sub {
                          $finished = 1;
                      });
    } until => sub { $finished };
}



fun _encode_type_and_value(Any $v) {
    my $type;

    if (ref($v)) {
        # An array maps to a sequence
        if (ref($v) eq 'ARRAY') {
            # Any refs mean we're sending binary data
            
            # Start by guessing we have an array of numeric strings,
            # but on the first value we encoutner that is either a reference
            # or a variable that isn't an integer or numeric.  Stop.
            $type = 'NS';
            foreach my $value (@$v) {
                if (ref($value)) {
                    $type = 'BS';
                    last;
                }
                my $element_flags = B::svref_2object(\$value)->FLAGS;
                if ($element_flags & (B::SVp_IOK | B::SVp_NOK)) {
                    next;
                }
                $type = 'SS';
                last;
            }
        } else {
            ref($v) eq 'SCALAR' || Carp::confess("Reference found but not a scalar");
            $type = 'B';
        }
    } else {
        my $flags = B::svref_2object(\$v)->FLAGS;
        if ($flags & B::SVp_POK) {
            $type = 'S';
        } elsif ($flags & (B::SVp_IOK | B::SVp_NOK)) {
            $type = 'N';
        } else {
            $type = 'S';
        }
    }
    
    if ($type eq 'N' || $type eq 'S') {
        defined($v) || Carp::confess("Attempt to encode undefined value");
        return ($type, "$v");
    } elsif ($type eq 'B') {
        return ($type, MIME::Base64::encode_base64(${$v}, ''));
    } elsif ($type eq 'NS' || $type eq 'SS') {
        return ($type, [map { "$_" } @$v]);
    } elsif ($type eq 'BS') {
        return ($type, [map { MIME::Base64::encode_base64(${$_}, '') } @$v]);
    } else {
        die("Unknown type for quoting and escaping: $type");
    }
}

fun _decode_type_and_value(Str $type, Any $value) {
    if ($type eq 'S' || $type eq 'SS') {
        return $value;
    } elsif ($type eq 'N') {
        return  0+$value;
    } elsif ($type eq 'B') {
        return MIME::Base64::decode_base64($value);
    } elsif ($type eq 'BS') {
        return [map { MIME::Base64::decode_base64($_) } @$value];
    } elsif ($type eq 'NS') {
        return [map { 0+$_} @$value];
    } else {
        die("Don't know how to decode type: $type");
    }
}


fun _decode_item_attributes(Maybe[HashRef] $item) {
    my $r;
    foreach my $key (keys %$item) {
        my $type = (keys %{$item->{$key}})[0];
        my $value = $item->{$key}->{$type};
        $r->{$key} = _decode_type_and_value($type, $item->{$key}->{$type});
    }
    return $r;
}

method _process_request(HTTP::Request $req, CodeRef $done?) {
    my $current_retry = 0;
    my $do_retry = 1;
    try_repeat {
        $do_retry = 0;
        
        my $sleep_amount = 0;
        if ($current_retry > 0) {
            $sleep_amount = (2 ** $current_retry * 50)/1000;
        }

        my $complete = sub {
            $self->_request($req)->transform(
                fail => sub {
                    my ($status, $resp, $req)= @_;
                    my $r;
                    if (defined($resp) && defined($resp->code)) {
                        if ($resp->code == 500) {
                            $do_retry = 1;
                            $current_retry++;
                        } elsif ($resp->code == 400) {
                            my $json = $resp->can('decoded_content')
                                ? $resp->decoded_content
                                : $resp->body; # Mojo
                            $r = decode_json($json);
                            if ($r->{__type} =~ /ProvisionedThroughputExceededException$/) {
                                # Need to sleep
                                $do_retry = 1;
                                $current_retry++;
                                    
                                
                            } else {
                                # extract the type into a better prettyier name.
                                if ($r->{__type} =~ /^com\.amazonaws\.dynamodb\.v20120810#(.+)$/) {
                                    $r->{type} = $1;
                                }
                            }
                        }
                    }
                    
                    if (defined($self->max_retries()) && $current_retry > $self->max_retries()) {
                        $do_retry = 0;
                    }

                    if (!$do_retry) {
                        if ($self->debug_failures()) {
                            print "DynamoDB Failure: $status\n";
                            if (defined($resp)) {
                                print "response:\n";
                                print $resp->as_string() . "\n";
                            }
                            if (defined($req)) {
                                print "Request:\n";
                                print $req->as_string() . "\n";
                            }
                        }
                        return $r || $status;
                    }
                },
                done => $done);
        };

        if ($sleep_amount > 0) {
            $self->{implementation}->delay($sleep_amount)->then($complete);
        } else {
            $complete->();
        }
    } until => sub { !$do_retry };
}

my $encode_key = sub {
    my $source = shift;
    my $r;
    foreach my $k (keys %$source) {
        my $v = $source->{$k};	
        # There is no sense in encoding undefined values or values that 
        # are the empty string.
        if (defined($v) && $v ne '') {
            # Reference $source->{$k} since the earlier test may cause
            # the value to be stringified.
            $r->{$k} = { _encode_type_and_value($source->{$k}) };
        }
    }
    return $r;
};


fun _encode_attribute_value_list(Any $value_list, Str $compare_op) {
    if ($compare_op =~ /^(EQ|NE|LE|LT|GE|GT|CONTAINS|NOT_CONTAINS|BEGINS_WITH)$/) {
        defined($value_list) || Carp::confess("No defined value for comparison operator: $compare_op");
        $value_list = [ { _encode_type_and_value($value_list) } ];
    } elsif ($compare_op eq 'IN') {
        if (!ref($value_list)) {
            $value_list = [$value_list];
        }
        $value_list = [ map { { _encode_type_and_value($_) } } @$value_list];
    } elsif ($compare_op eq 'BETWEEN') {
        ref($value_list) eq 'ARRAY' || Carp::confess("Use of BETWEEN comparison operator requires an array");
        scalar(@$value_list) == 2 || Carp::confess("BETWEEN comparison operator requires two values");
        $value_list = [ map { { _encode_type_and_value($_) } } @$value_list];
    }
    return $value_list;
}

my $encode_filter = sub {
    my $source = shift;

    my $r;

    foreach my $field_name (keys %$source) {
        my $f = $source->{$field_name};
        my $compare_op = $f->{ComparisonOperator} // 'EQ';
        $compare_op =~ /^(EQ|NE|LE|LT|GE|GT|NOT_NULL|NULL|CONTAINS|NOT_CONTAINS|BEGINS_WITH|IN|BETWEEN)$/ 
            || Carp::confess("Unknown comparison operator specified: $compare_op");
        
        $r->{$field_name} = {
            ComparisonOperator => $compare_op,
            (defined($f->{AttributeValueList}) ? (AttributeValueList => _encode_attribute_value_list($f->{AttributeValueList}, $compare_op)) : ())
        };
    }
    return $r;
};

my $parameter_type_definitions = {
    AttributesToGet => {},
    AttributeUpdates => {
        encode => sub {
            my $source = shift;
            my $r;
            ref($source) eq 'HASH' || Carp::confess("Attribute updates is not a hash ref");
            foreach my $k (keys %$source) {
                my $op = $source->{$k};
                ref($op) eq 'HASH' || Carp::confess("AttributeUpdate for field $k is not a hash ref:" . Data::Dumper->Dump([$op]));
                $r->{$k} = {
                    (defined($op->{Action}) ? (Action => $op->{Action}) : ()),
                    (defined($op->{Value}) ? (Value => { _encode_type_and_value($op->{Value}) }) : ()),
                };
            }
            return $r;
        }
    },
    # should be a boolean
    ConsistentRead => {},
    ConditionalOperator => {},
    ConditionExpression => {},
    ExclusiveStartKey => {
        encode => $encode_key,
    },
    ExclusiveStartTableName => {},    
    ExpressionAttributeNames => {},
    ExpressionAttributeValues => {
        encode => sub {
            my $source = shift;
            my $r;
            foreach my $key (grep { defined($source->{$_}) } keys %$source) {
                $r->{$key} = { _encode_type_and_value($source->{$key}) };
            }
            return $r;
        }
    },
    Expected => {
        encode => sub {
            my $source = shift;
            my $r;
            foreach my $key (keys %$source) {
                my $info = $source->{$key};

                if (defined($info->{AttributeValueList}) ) {
                    $r->{$key}->{AttributeValueList} = _encode_attribute_value_list($info->{AttributeValueList}, $info->{ComparisonOperator});
                }

                if (defined($info->{Exists})) {
                    $r->{$key}->{Exists} = $info->{Exists};
                }

                if (defined($info->{ComparisonOperator})) {
                    $r->{$key}->{ComparisonOperator} = $info->{ComparisonOperator};
                }
                
                if (defined($info->{Value})) {
                    $r->{$key}->{Value} = { _encode_type_and_value($info->{Value}) };
                }
            }
            return $r;
        },
    },
    FilterExpression => {},
    IndexName => {},
    Item => {
        encode => $encode_key,
    },
    Key => {
        encode => $encode_key,
    },
    Limit => {
        type_check => 'integer',
    },
    QueryFilter => {
        encode => $encode_filter,
    },
    ReturnConsumedCapacity => {},
    ReturnItemCollectionMetrics => {},
    ReturnValues => {},
    ScanIndexForward => {},
    ScanFilter => {
        encode => $encode_filter,
    },
    Segment => {
        type_check => 'integer',
    },
    Select => {},
    TableName => {},
    TotalSegments => {
        type_check => 'integer',
    },
    UpdateExpression => {},
};




# Build a parameter hash from all of the standardized parameters.
sub _make_payload {
    my $args = shift;
    my @field_names = @_;

    if (scalar(@field_names) == 0) {
        @field_names = keys %$args;
    }

    my %r;
    foreach my $field_name (@field_names) {
        my $value = $args->{$field_name};
        if (!defined($value)) {
            next;
        }
        my $def = $parameter_type_definitions->{$field_name} || Carp::confess("Unknown parameter type: $field_name");
        if (defined($value)) {
            if ($def->{type_check} && $def->{type_check} eq 'integer') {
                $value =~ /^\d+$/ || Carp::confess("$field_name is specified to be an integer but the value is not an integer: $value");
                $value = int($value);
            }
        } 

        if (defined($def->{encode})) {
            $value = $def->{encode}->($value);
        }

        if (defined($value)) {
            $r{$field_name} = $value;
        }
    }
    return \%r;
}

fun _decode_single_item_change_response(Str $response) {
    my $r = decode_json($response);
    if (defined($r->{Attributes})) {
        $r->{Attributes} = _decode_item_attributes($r->{Attributes});
    }
    
    if (defined($r->{ItemCollectionMetrics})) {
        foreach my $key (keys %{$r->{ItemCollectionMetrics}}) {
            foreach my $key_part (keys %{$r->{ItemCollectionMetrics}->{$key}}) {
                $r->{ItemCollectionMetrics}->{$key}->{$key_part} = _decode_item_attributes($r->{ItemCollectionMetrics}->{$key})
            }
        }
    }    
    return $r;
}


fun _create_key_schema(ArrayRef $source, HashRef $known_fields) {
    defined($source) || die("No source passed to create_key_schema");
    defined($known_fields) || die("No known fields passed to create_key_schmea");
    my @r;
    foreach my $field_name (@$source) {
        defined($known_fields->{$field_name}) || Carp::confess("Unknown field specified '$field_name' in schema, must be defined in fields.  schema:" . Data::Dumper->Dump([$source]));
        push @r, {
            AttributeName => $field_name,
            KeyType       => (scalar(@r) ? 'RANGE' : 'HASH')
        };
    }
    return \@r;
};



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Amazon::DynamoDB::20120810

=head1 VERSION

version 0.35

=head1 DESCRIPTION

=head2 new

Instantiates the API object.

Expects the following named parameters:

=over 4

=item * implementation - the object which provides a Future-returning C<request> method,
see L<Amazon::DynamoDB::NaHTTP> for example.

=item * host - the host (IP or hostname) to communicate with

=item * port - the port to use for HTTP(S) requests

=item * ssl - true for HTTPS, false for HTTP

=item * algorithm - which signing algorithm to use, default AWS4-HMAC-SHA256

=item * scope - the scope for requests, typically C<region/host/aws4_request>

=item * access_key - the access key for signing requests

=item * secret_key - the secret key for signing requests

=item * debug_failures - print errors if they occur

=item * max_retries - maximum number of retries for a request

=back

=head2 create_table

Creates a new table. It may take some time before the table is marked
as active - use L</wait_for_table_status> to poll until the status changes.

Amazon Documentation:

L<http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_CreateTable.html>

  $ddb->create_table(
     TableName => $table_name,
     ReadCapacityUnits => 2,
     WriteCapacityUnits => 2,
     AttributeDefinitions => {
         user_id => 'N',
         date => 'N',
     },
     KeySchema => ['user_id', 'date'],
     LocalSecondaryIndexes => [
         {
             IndexName => 'UserDateIndex',
             KeySchema => ['user_id', 'date'],
             Projection => {
                 ProjectionType => 'KEYS_ONLY',
             },
             ProvisionedThroughput => {
                 ReadCapacityUnits => 2,
                 WriteCapacityUnits => 2,
             }
         }
     ]
  );

=back

=head2 describe_table

Describes the given table.

Amazon Documentation:

L<http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_DescribeTable.html>

  $ddb->describe_table(TableName => $table_name);

=head2 delete_table

Delete a table.

Amazon Documentation:

L<http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_DeleteTable.html>

  $ddb->delete_table(TableName => $table_name)

=head2 wait_for_table_status

Waits for the given table to be marked as active.

=over 4

=item * TableName - the table name

=item * WaitInterval - default wait interval in seconds.

=item * DesiredStatus - status to expect before completing.  Defaults to ACTIVE

=back

  $ddb->wait_for_table_status(TableName => $table_name);

=head2 each_table

Run code for all current tables.

Takes a coderef as the first parameter, will call this for each table found.

Amazon Documentation:

L<http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_ListTables.html>

  my @all_tables;    
  $ddb->each_table(
        sub {
            my $table_name =shift;
            push @all_tables, $table_name;
        });

=head2 put_item

Writes a single item to the table.

Amazon Documentation:

L<http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_PutItem.html>

  $ddb->put_item(
     TableName => $table_name,
     Item => {
       name => 'Test Name'
     },
     ReturnValues => 'ALL_OLD');

=head2 update_item

Updates a single item in the table.

Amazon Documentation:

L<http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_UpdateItem.html>

  $ddb->update_item(
        TableName => $table_name,
        Key => {
            user_id => 2
        },
        AttributeUpdates => {
            name => {
                Action => 'PUT',
                Value => "Rusty Conover-3",
            },
            favorite_color => {
                Action => 'DELETE'
            },
            test_numbers => {
                Action => 'DELETE',
                Value => [500]
            },
            added_number => {
                Action => 'ADD',
                Value => 5,
            },
            subtracted_number => {
                Action => 'ADD',
                Value => -5,
            },
        });

=head2 delete_item

Deletes a single item from the table.

Amazon Documentation:

L<http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_DeleteItem.html>

  $ddb->delete_item(
    TableName => $table_name,
    Key => {
      user_id => 5
  });

=head2 get_item

Retrieve an items from one tables.

Amazon Documentation:

L<http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_GetItem.html>

  my $found_item;
  my $get = $ddb->get_item(
    sub {
      $found_item = shift;
    },
    TableName => $table_name,
    Key => {
      user_id => 6
    });

=head2 batch_write_item

Put or delete a collection of items.  

Has no restriction on the number of items able to be processed at one time.

Amazon Documentation:

L<http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_BatchWriteItem.html>

  $ddb->batch_write_item(
    RequestItems => {
       books => [
            {
                DeleteRequest => {
                    book_id => 3000,
                }
            },
       ],
       users => [
            {
                PutRequest => {
                    user_id => 3000,
                    name => "Test batch write",
                }
            },
            {
                PutRequest => {
                    user_id => 3001,
                    name => "Test batch write",
                }
            }
        ]
    });

=head2 batch_get_item

Retrieve a batch of items from one or more tables.

Takes a coderef which will be called for each found item.

Amazon Documentation:

L<http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_BatchGetItem.html>

Additional Parameters:

=over

=item * ResultLimit - limit on the total number of results to return.

=back

  $ddb->batch_get_item(
    sub {
        my ($table, $item) = @_;
    },
    RequestItems => {
        $table_name => {
            ConsistentRead => 'true',
            AttributesToGet => ['user_id', 'name'],
            Keys => [
                {
                    user_id => 1,
                },
            ],
        }
    })

=head2 scan

Scan a table for values with an optional filter expression.

Amazon Documentation:

L<http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_Scan.html>

Additional parameters:

=back

  $ddb->scan(
    sub {
      my $item = shift;
      push @found_items, $item;
    },
    TableName => $table_name,
    ScanFilter => {
      user_id => {
        ComparisonOperator => 'NOT_NULL',
      }
    });

=head1 NAME

Amazon::DynamoDB::20120810 - interact with DynamoDB using API version 20120810

=head1 METHODS - Internal 

The following methods are intended for internal use and are documented
purely for completeness - for normal operations see L</METHODS> instead.

=head2 make_request

Generates an L<HTTP::Request>.

=head1 FUNCTIONS - Internal

=head2 _encode_type_and_value

Returns an appropriate type (N, S, SS etc.) and stringified/encoded value for the given
value.

DynamoDB only uses strings even if there is a Numeric value specified,
so while the type will be expressed as a Number the value will be
stringified.

C<http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DataFormat.html>

=head1 AUTHORS

=over 4

=item *

Rusty Conover <rusty@luckydinosaur.com>

=item *

Tom Molesworth <cpan@entitymodel.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Tom Molesworth, copyright (c) 2014 Lucky Dinosaur LLC. L<http://www.luckydinosaur.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
