package CryptoTron::Modules;
use Filter::Macro;  # <-- The magic is found here.
# Lines below will be expanded into caller's code.
use CryptoTron::GetAccount;
use CryptoTron::GetAccountNet;
use CryptoTron::GetAccountResource;
use CryptoTron::GetReward;
use CryptoTron::BroadcastTransaction;
use CryptoTron::WithdrawBalance;
use CryptoTron::ParseAccount;
1;
