package CryptoTron::Modules;
use CryptoTron::FilterMacro;  # <-- The magic is found here.
# The lines below will be expanded into the caller's code.
use CryptoTron::BroadcastTransaction;
use CryptoTron::GetAccount;
use CryptoTron::GetAccountNet;
use CryptoTron::GetAccountResource;
use CryptoTron::GetBrokerage;
use CryptoTron::GetReward;
use CryptoTron::ParseAccount;
use CryptoTron::WithdrawBalance;
# Package terminator 1; will not be written to caller's code.
1;
