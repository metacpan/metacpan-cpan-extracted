use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Business::OnlinePayment::TransFirsteLink',
    VERSION_FROM => 'TransFirsteLink.pm',
    PREREQ_PM    => {
        Business::OnlinePayment        => '3',
        Business::OnlinePayment::HTTPS => '0.05',
        Tie::IxHash                    => '0',
    },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM => 'TransFirsteLink.pm',
            AUTHOR        => 'Jeff Finucane <transfirst@weasellips.com>',
          )
        : ()
    ),
);
