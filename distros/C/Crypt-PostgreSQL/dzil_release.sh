#!/bin/bash
#
# Script di release per Crypt-PostgreSQL
# Include il PERL5LIB necessario per il plugin SyncVersionFromDist
# Esegue build, test e upload su CPAN
#
# Uso: dzil_release.sh [--trial]
#

# Imposta PERL5LIB per includere la directory lib (dove si trova il plugin SyncVersionFromDist)
export PERL5LIB=lib:$PERL5LIB

# Determina se è un release trial o normale
if [ "$1" = "--trial" ]; then
    RELEASE_TYPE="TRIAL"
    DZIL_CMD="dzil release --trial"
else
    RELEASE_TYPE="NORMALE"
    DZIL_CMD="dzil release"
fi

echo "🚀 Avvio release $RELEASE_TYPE per Crypt-PostgreSQL..."
echo "📦 Questo comando eseguirà:"
echo "   1. Build del package"
echo "   2. Esecuzione dei test"
echo "   3. Upload su CPAN"
echo ""

# Esegue il release completo
$DZIL_CMD

# Verifica che il release sia andato a buon fine
if [ $? -eq 0 ]; then
    echo "✅ Release $RELEASE_TYPE completato con successo!"
    echo "🌐 Package caricato su CPAN"
else
    echo "❌ Errore durante il release $RELEASE_TYPE"
    exit 1
fi
