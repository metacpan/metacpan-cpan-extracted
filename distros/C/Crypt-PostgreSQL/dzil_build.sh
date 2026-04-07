#!/bin/bash
#
# Script di build per Crypt-PostgreSQL
# Include il PERL5LIB necessario per il plugin SyncVersionFromDist
# Crea una versione per la distribuzione
#
# Uso: dzil_build.sh [--trial]
#

# Imposta PERL5LIB per includere la directory lib (dove si trova il plugin SyncVersionFromDist)
export PERL5LIB=lib:$PERL5LIB

# Determina se è un build trial o normale
if [ "$1" = "--trial" ]; then
    BUILD_TYPE="TRIAL"
    DZIL_CMD="dzil build --trial"
    PACKAGE_SUFFIX="*-TRIAL.tar.gz"
else
    BUILD_TYPE="NORMALE"
    DZIL_CMD="dzil build"
    PACKAGE_SUFFIX="*.tar.gz"
fi

echo "🚀 Avvio build $BUILD_TYPE per Crypt-PostgreSQL..."
echo "📦 Questo creerà una versione per la distribuzione"
echo ""

# Esegue il build
$DZIL_CMD

# Verifica che il build sia andato a buon fine
if [ $? -eq 0 ]; then
    echo "✅ Build $BUILD_TYPE completato con successo!"
    echo "📦 Package creato: Crypt-PostgreSQL-$PACKAGE_SUFFIX"
else
    echo "❌ Errore durante il build $BUILD_TYPE"
    exit 1
fi
