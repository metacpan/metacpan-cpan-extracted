FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update &&\
    apt-get install -y --no-install-recommends \
            sudo adduser \
            libwww-perl \
            build-essential \
            git curl \
            libreadline-dev libssl-dev zlib1g-dev &&\
    apt-get -y clean &&\
    rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos '' user
RUN echo 'user ALL=(root) NOPASSWD:ALL' > /etc/sudoers.d/user

USER user
WORKDIR /home/user

RUN git clone https://github.com/tokuhirom/plenv.git ~/.plenv &&\
    git clone https://github.com/tokuhirom/Perl-Build.git ~/.plenv/plugins/perl-build/
RUN echo 'export PATH="$HOME/.plenv/bin:$PATH"' >> ~/.bash_profile &&\
    echo 'eval "$(plenv init -)"' >> ~/.bash_profile
RUN /bin/bash -l <<EOF
    plenv install 5.42.3
    plenv global 5.42.3
    plenv install-cpanm
EOF
