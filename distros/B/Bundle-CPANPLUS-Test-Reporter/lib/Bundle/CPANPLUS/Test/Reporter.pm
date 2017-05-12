package Bundle::CPANPLUS::Test::Reporter;

$VERSION = "0.05";

1;

### read here for motivation: 
### http://www.mail-archive.com/perl-qa-help@perl.org/msg01274.html

__END__

=head1 NAME

Bundle::CPANPLUS::Test::Reporter 

=head1 SYNOPSIS

    perl -MCPANPLUS -e 'install Bundle::CPANPLUS::Test::Reporter'

=head1 DESCRIPTION

Bundle to install all modules required & desired by CPANPLUS to 
provide automated test reporting to C<testers.cpan.org>

=head1 CONTENTS

File::Temp

HTTP::Request

Net::DNS

Net::SMTP

Test::Reporter 1.27

LWP

LWP::UserAgent

URI

YAML

=head1 AUTHOR

Jos Boumans <kane@cpan.org>

=cut 
