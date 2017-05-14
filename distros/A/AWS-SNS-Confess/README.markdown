# NAME

AWS::S3 - Publish Errors, with a full stack trace to an Amazon SNS
topic

# SYNOPSIS

    use AWS::SNS::Confess 'confess';
    AWS::SNS::Confess::setup(
      access_key_id => 'E654SAKIASDD64ERAF0O',
      secret_access_key => 'LgTZ25nCD+9LiCV6ujofudY1D6e2vfK0R4GLsI4H'
      topic => 'arn:aws:sns:us-east-1:738734873:YourTopic',
    );
    confess "Something went wrong";



# DESCRIPTION

AWS::SNS::Confess uses [Amazon::SNS](http://search.cpan.org/perldoc?Amazon::SNS) to post any errors to an Amazon SNS
feed for more robust management from there.



# PUBLIC METHODS

## setup( access_key_id => $aws_access_key_id, secret_access_key => $aws_secret_access_key, topic => $aws_topic );

Sets up to send errors to the given AWS Account and Topic

## confess( $msg );

Publishes the given error message to SNS with a full stack trace

# SEE ALSO

[Amazon::SNS](http://search.cpan.org/perldoc?Amazon::SNS)

[Carp](http://search.cpan.org/perldoc?Carp)