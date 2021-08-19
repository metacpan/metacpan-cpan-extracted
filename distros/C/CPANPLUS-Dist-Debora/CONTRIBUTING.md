# Contributing to CPANPLUS::Dist::Debora

The code for this distribution is hosted at
https://gitlab.com/voegelas/cpanplus-dist-debora.

Grab the latest version using the command:

    git clone https://gitlab.com/voegelas/cpanplus-dist-debora.git

You can submit code changes by forking the repository, pushing your code
changes to your clone, and then submitting a pull request.

Please install Perl::Critic and Perl::Tidy and use perlcritic and perltidy
before submitting patches.

The tests require Test::MockObject, which can be installed with the following
command:

    cpanp i Test::MockObject --format=CPANPLUS::Dist::Debora

Run the tests using the prove tool:

    prove -l

The distribution is managed with [Dist::Zilla](https://dzil.org/), which can be
installed as follows:

    cpanp i Dist::Zilla \
        Dist::Zilla::Plugin::CopyFilesFromBuild \
        Dist::Zilla::Plugin::Prereqs::FromCPANfile \
        Dist::Zilla::Plugin::Test::Kwalitee \
        Pod::Coverage::TrustPod \
        Test::Kwalitee \
        Test::Pod::Coverage \
        --format=CPANPLUS::Dist::Debora

Once installed, here are some dzil commands you might try:

    dzil build
    dzil test
    dzil test --release
