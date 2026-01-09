#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${HERE}/.." && pwd)"

ENV_FILE="${HERE}/sdseasydyn.env"
if [[ -f "${ENV_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
fi

exec /usr/bin/env perl -I"${ROOT}/lib" "${ROOT}/bin/sdseasydyn" "$@"

