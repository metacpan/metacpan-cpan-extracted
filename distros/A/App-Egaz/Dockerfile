FROM homebrew/brew
LABEL maintainer="Qiang Wang <wang-q@outlook.com>"

# Build
# docker build -t wangq/egaz .

# Run
# docker run --rm wangq/egaz:master egaz help
# docker run --rm wangq/egaz:master bash share/check_dep.sh

# Github actions
# https://docs.docker.com/ci-cd/github-actions/

# Change this when Perl updated
ENV PATH=/home/linuxbrew/bin:/home/linuxbrew/.linuxbrew/Cellar/perl/5.34.0/bin:$PATH

RUN true \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
        poa

# Perl & Python
# Text::Soundex and h5py are needed by RepeatMasker 4.1.1
RUN true \
 && export HOMEBREW_NO_ANALYTICS=1 \
 && export HOMEBREW_NO_AUTO_UPDATE=1 \
 && brew install perl \
 && curl -L https://cpanmin.us | perl - App::cpanminus \
 && cpanm -nq Text::Soundex \
 && brew install python \
 && pip3 install h5py \
 && rm -fr $(brew --cache)/* \
 && rm -fr /root/.cpan \
 && rm -fr /root/.gem \
 && rm -fr /root/.cpanm

# Brew packages
RUN true \
 && export HOMEBREW_NO_ANALYTICS=1 \
 && export HOMEBREW_NO_AUTO_UPDATE=1 \
 && brew install aria2 jq pup datamash miller \
 && brew install bcftools \
 && brew install mafft \
 && brew install parallel \
 && brew install pigz \
 && brew install samtools \
 && brew install brewsci/bio/fasttree \
 && brew install brewsci/bio/lastz \
 && brew install brewsci/bio/muscle \
 && brew install brewsci/bio/raxml \
 && brew install brewsci/bio/snp-sites \
 && brew install wang-q/tap/circos@0.69.9 \
 && brew install wang-q/tap/faops \
 && brew install wang-q/tap/sparsemem \
 && brew install wang-q/tap/multiz \
 && brew install wang-q/tap/intspan \
 && brew install wang-q/tap/tsv-utils \
 && rm -fr $(brew --cache)/*

# HOME bin
RUN true \
 && mkdir -p /home/linuxbrew/bin \
 && curl -L https://github.com/wang-q/ubuntu/releases/download/20190906/jkbin-egaz-ubuntu-1404-2011.tar.gz | \
    tar -xvzf - \
 && mv x86_64/* /home/linuxbrew/bin/ \
 && curl -O http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/faToTwoBit \
 && chmod +x faToTwoBit \
 && mv faToTwoBit /home/linuxbrew/bin/

# RepeatMasker
# https://stackoverflow.com/questions/57629010/linuxbrew-curl-certificate-issue
RUN true \
 && export HOMEBREW_NO_ANALYTICS=1 \
 && export HOMEBREW_NO_AUTO_UPDATE=1 \
 && export HOMEBREW_CURLRC=1 \
 && echo "--ciphers DEFAULT@SECLEVEL=1" >> $HOME/.curlrc \
 && brew install brewsci/bio/trf \
 && brew install hmmer \
 && brew install wang-q/tap/rmblast@2.10.0 \
 && brew install wang-q/tap/repeatmasker@4.1.1 \
 && cd $(brew --prefix)/Cellar/repeatmasker@4.1.1/4.1.1/libexec \
 && perl configure \
        -hmmer_dir=$(brew --prefix)/bin \
        -rmblast_dir=$(brew --prefix)/bin \
        -libdir=$(brew --prefix)/Cellar/repeatmasker@4.1.1/4.1.1/libexec/Libraries \
        -trf_prgm=$(brew --prefix)/bin/trf \
        -default_search_engine=rmblast \
 && rm -fr $(brew --cache)/*

# R
RUN true \
 && export HOMEBREW_NO_ANALYTICS=1 \
 && export HOMEBREW_NO_AUTO_UPDATE=1 \
 && brew install r \
 && Rscript -e 'install.packages("extrafont", repos="http://cran.rstudio.com")' \
 && Rscript -e 'install.packages("VennDiagram", repos="http://cran.rstudio.com")' \
 && Rscript -e 'install.packages("ggplot2", repos="http://cran.rstudio.com")' \
 && Rscript -e 'install.packages("scales", repos="http://cran.rstudio.com")' \
 && Rscript -e 'install.packages("gridExtra", repos="http://cran.rstudio.com")' \
 && Rscript -e 'install.packages("readr", repos="http://cran.rstudio.com")' \
 && Rscript -e 'install.packages("ape", repos="http://cran.rstudio.com")' \
 && Rscript -e 'library(extrafont); font_import(prompt = FALSE); fonts();' \
 && rm -fr $(brew --cache)/*

WORKDIR /home/linuxbrew/App-Egaz
ADD . .

RUN true \
 && cpanm -nq https://github.com/wang-q/App-Plotr.git \
 && cpanm -nq --installdeps --with-develop . \
 && cpanm -nq . \
 && perl Build.PL \
 && ./Build build \
 && ./Build test \
 && ./Build install \
 && ./Build clean \
 && rm -fr /root/.cpanm
