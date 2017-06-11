#!/bin/bash

set -e
set -u

echo Please check this file for correctness before running.
echo It does some things that might be dangerous, so it will
echo not continue to run until you\'ve edited it.
echo It uses debootstrap to install a 'stretch' system into the system/ directory
exit 1

mkdir system
debootstrap stretch system

# Install perlbrew, and perl-5.24.1
cat > system/install.sh <<'EOF'
#!/bin/bash
set -e
set -u
apt-get install -y build-essential perlbrew locales
localedef -i en_US -f UTF-8 en_US.UTF-8
export PERLBREW_ROOT=/opt/perlbrew
mkdir -p $PERLBREW_ROOT
perlbrew init
perlbrew install perl-5.24.1
perlbrew switch perl-5.24.1
perlbrew install-cpanm
EOF

cat > system/etc/profile.d/perlbrew.sh << EOF
export PERLBREW_ROOT=/opt/perlbrew
EOF

chmod +x system/install.sh

# This should now install perlbrew, switch to perlbrew to 5.24.1, and install cpanm
chroot system /install.sh

echo The system is now ready to be used
