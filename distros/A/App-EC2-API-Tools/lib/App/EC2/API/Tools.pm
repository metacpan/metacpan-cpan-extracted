package App::EC2::API::Tools;
$App::EC2::API::Tools::VERSION = '0.2';
=head1 NAME

App::EC2::API::Tools - ec2-api api tool wrapper scirpt

=head1 DESCRIPTION

This script will make an easy entry to run / install / and upgrade ec2-api api tools

=head1 FAQ

=head2 I have java installed, but need to donwload and setup EC2 api tool.

 ec2-api install ec2-api-tools

=head2 A new version of EC2 api tool. How to upgrde?

 ec2-api upgrade ec2-api-tools

=head2 What about java? seems like EC2 api tools required JAVA

 ec2-api install java

=head2 I need to install both JAVA and EC2 api tools

 ec2-api setup

=head2 List all availabe ec2 api scripts

 ec2-api exec

=head2 I don't know what is the name of the script. How to find it?

 ec2-api exec <anything you can think of to do>

 e.g. I want to start an instance

 ec2-api exec start

=head2 Show help page of the command

 ec2-api help ec2-stop-instances

=cut

1;
