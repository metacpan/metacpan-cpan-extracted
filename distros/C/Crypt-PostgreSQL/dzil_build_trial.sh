#!/bin/bash
#
# Script di build TRIAL per Crypt-PostgreSQL
# Chiama dzil_build.sh con il parametro --trial
#

echo "🧪 Avvio build TRIAL per Crypt-PostgreSQL..."
echo "📦 Questo creerà una versione di test"
echo ""

# Chiama dzil_build.sh con --trial
./dzil_build.sh --trial
