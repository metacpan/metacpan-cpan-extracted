#!/bin/bash
#
# Script di release TRIAL per Crypt-PostgreSQL
# Chiama dzil_release.sh con il parametro --trial
#

echo "🧪 Avvio release TRIAL per Crypt-PostgreSQL..."
echo "📝 Questo creerà una versione di test su CPAN"
echo ""

# Chiama dzil_release.sh con --trial
./dzil_release.sh --trial
