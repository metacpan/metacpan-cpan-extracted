#!/bin/bash

set -x
set -eu

start_dir=$(pwd)

PARALLEL_VERSION="20150522"
PARALLEL_DOWNLOAD_FILENAME="parallel-${PARALLEL_VERSION}.tar.bz2"
PARALLEL_URL="http://ftp.gnu.org/gnu/parallel/${PARALLEL_DOWNLOAD_FILENAME}"

PRODIGAL_VERSION="2.6.2"
PRODIGAL_DOWNLOAD_FILENAME="prodigal-${PRODIGAL_VERSION}.linux"
PRODIGAL_URL="https://github.com/hyattpd/Prodigal/releases/download/v${PRODIGAL_VERSION}/prodigal.linux"

HMMER_VERSION="3.1b2"
HMMER_DOWNLOAD_FILENAME="hmmer-${HMMER_VERSION}.tar.gz"
HMMER_URL="http://eddylab.org/software/hmmer3/${HMMER_VERSION}/hmmer-${HMMER_VERSION}-linux-intel-x86_64.tar.gz"

# Make an install location
if [ ! -d 'build' ]; then
  mkdir build
fi
cd build
build_dir=$(pwd)

# Install apt packages
sudo apt-get update -q
sudo apt-get install -y -q g++ \
	                   libexpat1-dev \
                           ncbi-blast+

download () {
  download_url=$1
  download_path=$2
  if [ -e "$download_path" ]; then
    echo "Skipping download of $download_url, $download_path already exists"
  else
    echo "Downloading $download_url to $download_path"
    wget $download_url -O $download_path
  fi
}

# Download parallel
PARALLEL_DOWNLOAD_PATH="$(pwd)/${PARALLEL_DOWNLOAD_FILENAME}"
download $PARALLEL_URL $PARALLEL_DOWNLOAD_PATH

# Download prodigal
PRODIGAL_DOWNLOAD_PATH="$(pwd)/${PRODIGAL_DOWNLOAD_FILENAME}"
download $PRODIGAL_URL $PRODIGAL_DOWNLOAD_PATH

# Download hmmer
HMMER_DOWNLOAD_PATH="$(pwd)/${HMMER_DOWNLOAD_FILENAME}"
download $HMMER_URL $HMMER_DOWNLOAD_PATH

untar () {
  to_untar=$1
  expected_directory=$2
  if [ -d "$expected_directory" ]; then
    echo "Already untarred $to_untar to $expected_directory, skipping"
  else
    echo "Untarring $to_untar to $expected_directory"
    tar xzvf $to_untar
  fi
}


# Untar parallel
PARALLEL_BUILD_DIR="$(pwd)/parallel-${PARALLEL_VERSION}"
if [ -d "$PARALLEL_BUILD_DIR" ]; then
  echo "Parallel already untarred to $PARALLEL_BUILD_DIR, skipping"
else
  echo "Untarring parallel to $PARALLEL_BUILD_DIR"
  tar xjvf $PARALLEL_DOWNLOAD_PATH
fi

# Make prodigal directory
PRODIGAL_DIR="$(pwd)/prodigal-${PRODIGAL_VERSION}"
if [ -d "$PRODIGAL_DIR" ]; then
  echo "$PRODIGAL_DIR already exists, skipping"
else
  echo "Creating $PRODIGAL_DIR"
  mkdir -p $PRODIGAL_DIR
fi

# Untar hmmer
HMMER_BUILD_DIR="$(pwd)/hmmer-${HMMER_VERSION}-linux-intel-x86_64"
untar $HMMER_DOWNLOAD_PATH $HMMER_BUILD_DIR

# Build parallel
cd $PARALLEL_BUILD_DIR

if [ -e "$PARALLEL_BUILD_DIR/src/parallel" ]; then
  echo "Parallel already built, skipping"
else
  echo "Building parallel"
  ./configure
  make
fi

# Create prodigal symlink
cd $PRODIGAL_DIR

if [ -e "$PRODIGAL_DIR/prodigal" ]; then
  echo "Prodiagl already exists in $PRODIGAL_DIR"
else
  echo "Creating prodigal symlink"
  cp $PRODIGAL_DOWNLOAD_PATH $PRODIGAL_DIR
  chmod u+x "${PRODIGAL_DIR}/${PRODIGAL_DOWNLOAD_FILENAME}"
  ln -s "${PRODIGAL_DIR}/${PRODIGAL_DOWNLOAD_FILENAME}" ${PRODIGAL_DIR}/prodigal
fi

# Add things to PATH
update_path () {
  new_dir=$1
  if [[ ! "$PATH" =~ (^|:)"${new_dir}"(:|$) ]]; then
    export PATH=${new_dir}:${PATH}
  fi
}

export PATH
PARALLEL_BIN_DIR="$PARALLEL_BUILD_DIR/src"
update_path $PARALLEL_BIN_DIR
update_path $PRODIGAL_DIR
HMMER_BIN_DIR="${HMMER_BUILD_DIR}/binaries"
update_path ${HMMER_BIN_DIR}

cd $start_dir
cpanm Dist::Zilla
dzil authordeps --missing | cpanm
cpanm File::Slurper \
      Bio::SearchIO \
      Text::CSV \
      XML::Simple

cd $start_dir

set +eu
set +x
