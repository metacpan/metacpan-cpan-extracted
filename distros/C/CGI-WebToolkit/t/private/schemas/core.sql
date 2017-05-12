/* standard database tables for WTK */

create table `session` (
	`id` int(11) not null auto_increment primary key,
	`session_id` varchar(32) not null,
	`content` text not null,
	`last_update` int(16) not null
);

create table `user` (
	`id` int(11) not null auto_increment primary key,
	`loginname` varchar(255) not null,
	`password` varchar(32) not null,
	`language` varchar(5) not null
);

create table `cache` (
	`id` int(11) not null auto_increment primary key,
	`hash` varchar(32) not null,
	`content` mediumtext not null,
	`last_update` int(16) not null
);

create table `phrase` (
	`id` int(11) not null auto_increment primary key,
	`language` varchar(5) not null,
	`name` varchar(32) not null,
	`translations` text not null
);

